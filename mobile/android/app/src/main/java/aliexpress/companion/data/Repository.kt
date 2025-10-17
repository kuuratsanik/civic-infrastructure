package aliexpress.companion.data

/**
 * Repository layer for Product data.
 *
 * This repository abstracts data sources (local cache vs remote API)
 * and provides a clean API for ViewModels.
 *
 * Framework Integration:
 * - Works with Data Caching Agent for intelligent caching
 * - Communicates with cloud agents via API
 * - Emits lineage events for audit trail
 */
class ProductRepository(
    private val productDao: ProductDao,
    private val priceHistoryDao: PriceHistoryDao,
    // TODO: Add API service in Phase 2
    // private val apiService: ApiService
) {

    // ============================================
    // LOCAL CACHE OPERATIONS (Data Caching Agent)
    // ============================================

    /**
     * Get all cached products.
     */
    fun getAllProducts() = productDao.getAll()

    /**
     * Get product by ID.
     * Checks local cache first, fetches from API if not found.
     */
    suspend fun getProduct(productId: String): Product? {
        // Try local cache first
        val cachedProduct = productDao.getById(productId)

        // TODO: In Phase 2, fetch from API if not cached or stale
        // if (cachedProduct == null || cachedProduct.isCacheStale()) {
        //     val freshProduct = apiService.getProduct(productId)
        //     productDao.insert(freshProduct)
        //     return freshProduct
        // }

        return null // Placeholder
    }

    /**
     * Search products by query.
     */
    fun searchProducts(query: String) = productDao.search(query)

    /**
     * Get products by category.
     */
    fun getProductsByCategory(category: String) = productDao.getByCategory(category)

    /**
     * Get recently viewed products.
     */
    fun getRecentlyViewed(limit: Int = 20) = productDao.getRecentlyViewed(limit)

    /**
     * Record product access (for cache scoring).
     */
    suspend fun recordProductAccess(productId: String) {
        productDao.recordAccess(productId)
    }

    /**
     * Update cache score (from ML model).
     */
    suspend fun updateCacheScore(productId: String, score: Float) {
        productDao.updateCacheScore(productId, score)
    }

    /**
     * Get stale products for refresh.
     */
    fun getStaleCachedProducts() = productDao.getStaleCachedProducts()

    /**
     * Clear old cache entries.
     */
    suspend fun clearStaleCache(maxAgeHours: Int = 168) {
        productDao.deleteStaleCachedProducts(maxAgeHours)
    }

    // ============================================
    // WISHLIST OPERATIONS
    // ============================================

    /**
     * Get wishlist products.
     */
    fun getWishlist() = productDao.getWishlist()

    /**
     * Add product to wishlist.
     */
    suspend fun addToWishlist(productId: String) {
        productDao.addToWishlist(productId)

        // TODO: Sync with cloud in Phase 2
        // apiService.syncWishlist(productId, action = "add")
    }

    /**
     * Remove product from wishlist.
     */
    suspend fun removeFromWishlist(productId: String) {
        productDao.removeFromWishlist(productId)

        // TODO: Sync with cloud in Phase 2
        // apiService.syncWishlist(productId, action = "remove")
    }

    // ============================================
    // PRICE TRACKING OPERATIONS
    // ============================================

    /**
     * Get tracked products.
     */
    fun getTrackedProducts() = productDao.getTrackedProducts()

    /**
     * Start tracking product price.
     */
    suspend fun startTracking(productId: String, priceTarget: Double? = null) {
        productDao.startTracking(productId, priceTarget)

        // TODO: In Phase 2, notify Price Tracking Agent
        // apiService.startPriceTracking(productId, priceTarget)

        // Emit lineage event
        // lineageBus.emit("price_tracking_started", payload = {
        //     "product_id": productId,
        //     "price_target": priceTarget
        // })
    }

    /**
     * Stop tracking product price.
     */
    suspend fun stopTracking(productId: String) {
        productDao.stopTracking(productId)

        // TODO: In Phase 2, notify Price Tracking Agent
        // apiService.stopPriceTracking(productId)
    }

    /**
     * Update product price (from Price Tracking Agent).
     */
    suspend fun updatePrice(productId: String, newPrice: Double) {
        productDao.updatePrice(productId, newPrice)
    }

    /**
     * Get price history for a product.
     */
    fun getPriceHistory(productId: String, limit: Int = 100) =
        priceHistoryDao.getHistory(productId, limit)

    /**
     * Get price history within date range.
     */
    fun getPriceHistoryInRange(productId: String, startTime: Long, endTime: Long) =
        priceHistoryDao.getHistoryInRange(productId, startTime, endTime)

    /**
     * Record price change.
     */
    suspend fun recordPriceChange(productId: String, price: Double, currency: String = "USD") {
        val entry = PriceHistoryEntry(
            productId = productId,
            price = price,
            currency = currency
        )
        priceHistoryDao.insert(entry)
    }

    /**
     * Clean old price history.
     */
    suspend fun cleanOldPriceHistory() {
        priceHistoryDao.deleteOldHistory()
    }

    // ============================================
    // CACHE MANAGEMENT (Data Caching Agent)
    // ============================================

    /**
     * Get cache size.
     */
    suspend fun getCacheSize(): Int {
        return productDao.getCacheSize()
    }

    /**
     * Evict low-value products from cache.
     */
    suspend fun evictLowValueProducts(limit: Int = 10) {
        val lowValueProducts = productDao.getLowValueProducts(limit)
        productDao.deleteAll(lowValueProducts)
    }

    /**
     * Clear entire cache.
     */
    suspend fun clearCache() {
        productDao.deleteAllProducts()
    }
}

/**
 * Repository layer for Order data.
 */
class OrderRepository(
    private val orderDao: OrderDao
    // TODO: Add API service in Phase 2
) {

    /**
     * Get all orders.
     */
    fun getAllOrders() = orderDao.getAll()

    /**
     * Get order by ID.
     */
    fun getOrder(orderId: String) = orderDao.getById(orderId)

    /**
     * Get active orders.
     */
    fun getActiveOrders() = orderDao.getActiveOrders()

    /**
     * Get orders by status.
     */
    fun getOrdersByStatus(status: OrderStatus) = orderDao.getByStatus(status)

    /**
     * Insert or update order.
     */
    suspend fun saveOrder(order: Order) {
        orderDao.insert(order)
    }

    /**
     * Update order status.
     */
    suspend fun updateOrderStatus(orderId: String, status: OrderStatus) {
        orderDao.updateStatus(orderId, status)

        // TODO: In Phase 4, notify Logistics Agent
        // apiService.updateOrderStatus(orderId, status)
    }

    /**
     * Update tracking information.
     */
    suspend fun updateTracking(orderId: String, trackingNumber: String, carrier: String) {
        orderDao.updateTracking(orderId, trackingNumber, carrier)

        // TODO: In Phase 4, notify Shipment Tracking Agent
        // apiService.updateTracking(orderId, trackingNumber, carrier)
    }

    /**
     * Delete order.
     */
    suspend fun deleteOrder(order: Order) {
        orderDao.delete(order)
    }
}

/**
 * Repository layer for User Preferences.
 *
 * Used by UI Personalization Agent.
 */
class UserPreferencesRepository(
    private val preferencesDao: UserPreferencesDao
) {

    private val userId = "default" // Single user for now

    /**
     * Get user preferences.
     */
    fun getPreferences() = preferencesDao.get(userId)

    /**
     * Save user preferences.
     */
    suspend fun savePreferences(preferences: UserPreferences) {
        preferencesDao.insert(preferences)
    }

    /**
     * Update theme.
     */
    suspend fun updateTheme(theme: String) {
        preferencesDao.updateTheme(theme, userId)
    }

    /**
     * Update notification preferences.
     */
    suspend fun updateNotificationPreferences(
        priceDrops: Boolean,
        deals: Boolean,
        shipping: Boolean,
        recommendations: Boolean,
        marketing: Boolean
    ) {
        preferencesDao.updateNotificationPreferences(
            priceDrops, deals, shipping, recommendations, marketing, userId
        )
    }
}

/**
 * Repository layer for User Interactions.
 *
 * Used by UI Personalization Agent for learning.
 */
class UserInteractionRepository(
    private val interactionDao: UserInteractionDao
) {

    /**
     * Get recent interactions.
     */
    fun getRecentInteractions(limit: Int = 1000) =
        interactionDao.getRecent(limit)

    /**
     * Get interactions by type.
     */
    fun getInteractionsByType(type: InteractionType, limit: Int = 100) =
        interactionDao.getByType(type, limit)

    /**
     * Get interactions for a product.
     */
    fun getProductInteractions(productId: String) =
        interactionDao.getByProduct(productId)

    /**
     * Record interaction.
     */
    suspend fun recordInteraction(interaction: UserInteraction) {
        interactionDao.insert(interaction)

        // TODO: In Phase 1, send to UI Personalization Agent for learning
        // uiPersonalizationAgent.learnFromInteraction(interaction)
    }

    /**
     * Record screen view.
     */
    suspend fun recordScreenView(screenName: String, duration: Long = 0) {
        val interaction = UserInteraction(
            type = InteractionType.SCREEN_VIEW,
            screenName = screenName,
            duration = duration
        )
        interactionDao.insert(interaction)
    }

    /**
     * Record product view.
     */
    suspend fun recordProductView(productId: String, duration: Long = 0) {
        val interaction = UserInteraction(
            type = InteractionType.PRODUCT_VIEW,
            screenName = "product_detail",
            productId = productId,
            duration = duration
        )
        interactionDao.insert(interaction)
    }

    /**
     * Record search.
     */
    suspend fun recordSearch(query: String) {
        val interaction = UserInteraction(
            type = InteractionType.SEARCH,
            screenName = "search",
            action = query
        )
        interactionDao.insert(interaction)
    }

    /**
     * Clean old interactions.
     */
    suspend fun cleanOldInteractions() {
        interactionDao.deleteOldInteractions()
    }

    /**
     * Get interaction statistics.
     */
    suspend fun getInteractionStats(): Map<InteractionType, Int> {
        return interactionDao.getInteractionCountsByType()
    }
}
