package aliexpress.companion.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

/**
 * Data Access Object for Product entities.
 *
 * This DAO is used by the Data Caching Agent to manage local product cache.
 * All queries return Flow for reactive data updates in the UI.
 */
@Dao
interface ProductDao {

    // ============================================
    // QUERY OPERATIONS
    // ============================================

    /**
     * Get all cached products.
     * Used by: Product listing screens, search results
     */
    @Query("SELECT * FROM products ORDER BY lastAccessedAt DESC")
    fun getAll(): Flow<List<Product>>

    /**
     * Get a single product by ID.
     * Used by: Product detail screen
     */
    @Query("SELECT * FROM products WHERE id = :productId LIMIT 1")
    fun getById(productId: String): Flow<Product?>

    /**
     * Get all products in wishlist.
     * Used by: Wishlist screen
     */
    @Query("SELECT * FROM products WHERE isInWishlist = 1 ORDER BY addedToWishlistAt DESC")
    fun getWishlist(): Flow<List<Product>>

    /**
     * Get all tracked products (price monitoring).
     * Used by: Price tracking agent, Deals screen
     */
    @Query("SELECT * FROM products WHERE isTracked = 1 ORDER BY trackingStartedAt DESC")
    fun getTrackedProducts(): Flow<List<Product>>

    /**
     * Get products by category.
     * Used by: Category filtering
     */
    @Query("SELECT * FROM products WHERE category = :category ORDER BY lastAccessedAt DESC")
    fun getByCategory(category: String): Flow<List<Product>>

    /**
     * Search products by name or description.
     * Used by: Search functionality
     */
    @Query("""
        SELECT * FROM products
        WHERE name LIKE '%' || :query || '%'
        OR description LIKE '%' || :query || '%'
        ORDER BY lastAccessedAt DESC
    """)
    fun search(query: String): Flow<List<Product>>

    /**
     * Get products with stale cache (older than 24 hours).
     * Used by: Data Caching Agent for cache refresh
     */
    @Query("""
        SELECT * FROM products
        WHERE ((:currentTime - cachedAt) / 3600000) > 24
        ORDER BY lastAccessedAt DESC
    """)
    fun getStaleCachedProducts(currentTime: Long = System.currentTimeMillis()): Flow<List<Product>>

    /**
     * Get low-value products for cache eviction.
     * Used by: Data Caching Agent when cache size limit is reached
     */
    @Query("""
        SELECT * FROM products
        WHERE isInWishlist = 0 AND isTracked = 0
        ORDER BY cacheScore ASC, lastAccessedAt ASC
        LIMIT :limit
    """)
    suspend fun getLowValueProducts(limit: Int = 10): List<Product>

    /**
     * Get recently viewed products.
     * Used by: Home screen, Recently Viewed section
     */
    @Query("""
        SELECT * FROM products
        ORDER BY lastAccessedAt DESC
        LIMIT :limit
    """)
    fun getRecentlyViewed(limit: Int = 20): Flow<List<Product>>

    /**
     * Get products with price targets hit.
     * Used by: Notification Agent for price alerts
     */
    @Query("""
        SELECT * FROM products
        WHERE isTracked = 1
        AND priceTarget IS NOT NULL
        AND price <= priceTarget
    """)
    fun getProductsWithTargetHit(): Flow<List<Product>>

    /**
     * Get total cache size estimate (number of products).
     * Used by: Data Caching Agent for cache management
     */
    @Query("SELECT COUNT(*) FROM products")
    suspend fun getCacheSize(): Int

    // ============================================
    // INSERT/UPDATE OPERATIONS
    // ============================================

    /**
     * Insert a product (replace if exists).
     * Used by: Data Caching Agent when caching new products
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(product: Product)

    /**
     * Insert multiple products.
     * Used by: Bulk cache updates from API
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(products: List<Product>)

    /**
     * Update an existing product.
     * Used by: Price updates, wishlist changes
     */
    @Update
    suspend fun update(product: Product)

    /**
     * Update multiple products.
     * Used by: Batch price updates from Price Tracking Agent
     */
    @Update
    suspend fun updateAll(products: List<Product>)

    /**
     * Record product access (for cache scoring).
     * Used by: Data Caching Agent when user views a product
     */
    @Query("""
        UPDATE products
        SET lastAccessedAt = :timestamp,
            accessCount = accessCount + 1
        WHERE id = :productId
    """)
    suspend fun recordAccess(productId: String, timestamp: Long = System.currentTimeMillis())

    /**
     * Update cache score (ML prediction).
     * Used by: Data Caching Agent's ML model
     */
    @Query("UPDATE products SET cacheScore = :score WHERE id = :productId")
    suspend fun updateCacheScore(productId: String, score: Float)

    /**
     * Add product to wishlist.
     * Used by: Wishlist feature
     */
    @Query("""
        UPDATE products
        SET isInWishlist = 1,
            addedToWishlistAt = :timestamp
        WHERE id = :productId
    """)
    suspend fun addToWishlist(productId: String, timestamp: Long = System.currentTimeMillis())

    /**
     * Remove product from wishlist.
     * Used by: Wishlist feature
     */
    @Query("""
        UPDATE products
        SET isInWishlist = 0,
            addedToWishlistAt = NULL
        WHERE id = :productId
    """)
    suspend fun removeFromWishlist(productId: String)

    /**
     * Start tracking product price.
     * Used by: Price tracking feature
     */
    @Query("""
        UPDATE products
        SET isTracked = 1,
            trackingStartedAt = :timestamp,
            priceTarget = :priceTarget
        WHERE id = :productId
    """)
    suspend fun startTracking(
        productId: String,
        priceTarget: Double? = null,
        timestamp: Long = System.currentTimeMillis()
    )

    /**
     * Stop tracking product price.
     * Used by: Price tracking feature
     */
    @Query("""
        UPDATE products
        SET isTracked = 0,
            trackingStartedAt = NULL,
            priceTarget = NULL
        WHERE id = :productId
    """)
    suspend fun stopTracking(productId: String)

    /**
     * Update product price (from Price Tracking Agent).
     * Used by: Price Tracking Agent when detecting price changes
     */
    @Query("UPDATE products SET price = :newPrice, cachedAt = :timestamp WHERE id = :productId")
    suspend fun updatePrice(
        productId: String,
        newPrice: Double,
        timestamp: Long = System.currentTimeMillis()
    )

    // ============================================
    // DELETE OPERATIONS
    // ============================================

    /**
     * Delete a product from cache.
     * Used by: Cache eviction
     */
    @Delete
    suspend fun delete(product: Product)

    /**
     * Delete multiple products.
     * Used by: Bulk cache cleanup
     */
    @Delete
    suspend fun deleteAll(products: List<Product>)

    /**
     * Delete products by IDs.
     * Used by: Targeted cache cleanup
     */
    @Query("DELETE FROM products WHERE id IN (:productIds)")
    suspend fun deleteByIds(productIds: List<String>)

    /**
     * Delete all products from cache.
     * Used by: Clear cache functionality
     */
    @Query("DELETE FROM products")
    suspend fun deleteAllProducts()

    /**
     * Delete stale cached products.
     * Used by: Automated cache cleanup
     */
    @Query("""
        DELETE FROM products
        WHERE isInWishlist = 0
        AND isTracked = 0
        AND ((:currentTime - cachedAt) / 3600000) > :maxAgeHours
    """)
    suspend fun deleteStaleCachedProducts(
        maxAgeHours: Int = 168, // 7 days
        currentTime: Long = System.currentTimeMillis()
    )
}

/**
 * Data Access Object for Price History entries.
 *
 * Used by Price Tracking Agent and Predictive Pricing Agent.
 */
@Dao
interface PriceHistoryDao {

    /**
     * Get price history for a product.
     */
    @Query("""
        SELECT * FROM price_history
        WHERE productId = :productId
        ORDER BY timestamp DESC
        LIMIT :limit
    """)
    fun getHistory(productId: String, limit: Int = 100): Flow<List<PriceHistoryEntry>>

    /**
     * Get price history within a date range.
     */
    @Query("""
        SELECT * FROM price_history
        WHERE productId = :productId
        AND timestamp >= :startTime
        AND timestamp <= :endTime
        ORDER BY timestamp ASC
    """)
    fun getHistoryInRange(
        productId: String,
        startTime: Long,
        endTime: Long
    ): Flow<List<PriceHistoryEntry>>

    /**
     * Insert a price history entry.
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entry: PriceHistoryEntry)

    /**
     * Insert multiple price history entries.
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(entries: List<PriceHistoryEntry>)

    /**
     * Delete old price history (keep last 90 days).
     */
    @Query("""
        DELETE FROM price_history
        WHERE timestamp < :cutoffTime
    """)
    suspend fun deleteOldHistory(cutoffTime: Long = System.currentTimeMillis() - (90L * 24 * 60 * 60 * 1000))
}

/**
 * Data Access Object for Orders.
 *
 * Used by Order Tracking feature and Logistics Agent.
 */
@Dao
interface OrderDao {

    /**
     * Get all orders.
     */
    @Query("SELECT * FROM orders ORDER BY orderDate DESC")
    fun getAll(): Flow<List<Order>>

    /**
     * Get order by ID.
     */
    @Query("SELECT * FROM orders WHERE orderId = :orderId LIMIT 1")
    fun getById(orderId: String): Flow<Order?>

    /**
     * Get active orders (not delivered/cancelled).
     */
    @Query("""
        SELECT * FROM orders
        WHERE status NOT IN ('DELIVERED', 'CANCELLED', 'REFUNDED')
        ORDER BY orderDate DESC
    """)
    fun getActiveOrders(): Flow<List<Order>>

    /**
     * Get orders by status.
     */
    @Query("SELECT * FROM orders WHERE status = :status ORDER BY orderDate DESC")
    fun getByStatus(status: OrderStatus): Flow<List<Order>>

    /**
     * Insert an order.
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(order: Order)

    /**
     * Update an order.
     */
    @Update
    suspend fun update(order: Order)

    /**
     * Update order status.
     */
    @Query("""
        UPDATE orders
        SET status = :status,
            lastUpdateAt = :timestamp
        WHERE orderId = :orderId
    """)
    suspend fun updateStatus(
        orderId: String,
        status: OrderStatus,
        timestamp: Long = System.currentTimeMillis()
    )

    /**
     * Update tracking information.
     */
    @Query("""
        UPDATE orders
        SET trackingNumber = :trackingNumber,
            carrier = :carrier,
            lastUpdateAt = :timestamp
        WHERE orderId = :orderId
    """)
    suspend fun updateTracking(
        orderId: String,
        trackingNumber: String,
        carrier: String,
        timestamp: Long = System.currentTimeMillis()
    )

    /**
     * Delete an order.
     */
    @Delete
    suspend fun delete(order: Order)
}

/**
 * Data Access Object for User Preferences.
 *
 * Used by UI Personalization Agent.
 */
@Dao
interface UserPreferencesDao {

    /**
     * Get user preferences.
     */
    @Query("SELECT * FROM user_preferences WHERE userId = :userId LIMIT 1")
    fun get(userId: String = "default"): Flow<UserPreferences?>

    /**
     * Insert or update user preferences.
     */
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(preferences: UserPreferences)

    /**
     * Update theme.
     */
    @Query("UPDATE user_preferences SET theme = :theme WHERE userId = :userId")
    suspend fun updateTheme(theme: String, userId: String = "default")

    /**
     * Update notification preferences.
     */
    @Query("""
        UPDATE user_preferences
        SET enablePriceDropNotifications = :priceDrops,
            enableDealNotifications = :deals,
            enableShippingNotifications = :shipping,
            enableRecommendationNotifications = :recommendations,
            enableMarketingNotifications = :marketing
        WHERE userId = :userId
    """)
    suspend fun updateNotificationPreferences(
        priceDrops: Boolean,
        deals: Boolean,
        shipping: Boolean,
        recommendations: Boolean,
        marketing: Boolean,
        userId: String = "default"
    )
}

/**
 * Data Access Object for User Interactions.
 *
 * Used by UI Personalization Agent for learning user behavior.
 */
@Dao
interface UserInteractionDao {

    /**
     * Get recent interactions.
     */
    @Query("""
        SELECT * FROM user_interactions
        ORDER BY timestamp DESC
        LIMIT :limit
    """)
    fun getRecent(limit: Int = 1000): Flow<List<UserInteraction>>

    /**
     * Get interactions by type.
     */
    @Query("""
        SELECT * FROM user_interactions
        WHERE type = :type
        ORDER BY timestamp DESC
        LIMIT :limit
    """)
    fun getByType(type: InteractionType, limit: Int = 100): Flow<List<UserInteraction>>

    /**
     * Get interactions for a specific product.
     */
    @Query("""
        SELECT * FROM user_interactions
        WHERE productId = :productId
        ORDER BY timestamp DESC
    """)
    fun getByProduct(productId: String): Flow<List<UserInteraction>>

    /**
     * Insert an interaction.
     */
    @Insert
    suspend fun insert(interaction: UserInteraction)

    /**
     * Insert multiple interactions.
     */
    @Insert
    suspend fun insertAll(interactions: List<UserInteraction>)

    /**
     * Delete old interactions (keep last 30 days).
     */
    @Query("""
        DELETE FROM user_interactions
        WHERE timestamp < :cutoffTime
    """)
    suspend fun deleteOldInteractions(
        cutoffTime: Long = System.currentTimeMillis() - (30L * 24 * 60 * 60 * 1000)
    )

    /**
     * Get interaction count by type (for analytics).
     */
    @Query("""
        SELECT type, COUNT(*) as count
        FROM user_interactions
        GROUP BY type
    """)
    suspend fun getInteractionCountsByType(): Map<InteractionType, Int>
}
