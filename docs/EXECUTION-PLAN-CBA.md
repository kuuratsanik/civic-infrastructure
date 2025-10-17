# 🚀 Execution Plan: C → B → A (4-Week Sprint to MVP)

**Strategy:** Build foundation → Add intelligence → Launch product
**Timeline:** 4 weeks
**Target:** 1,000 beta users, 50 core features, $10K/month revenue

---

## 📅 Week-by-Week Breakdown

### **Week 1: Option C - Expand Android MVVM Foundation**

**Goal:** Extend existing architecture with 3 new entities + DAOs
**Deliverables:** Complete data layer for Phase 1 (100 features)

#### **Day 1-2: Add Wishlist Entities**

```kotlin
// mobile/android/app/src/main/java/aliexpress/companion/data/Wishlist.kt

package aliexpress.companion.data

import androidx.room.*
import kotlinx.coroutines.flow.Flow
import java.util.UUID

// Features 36-41: Multiple wishlists
@Entity(tableName = "wishlists")
data class Wishlist(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val userId: String,
    val name: String,
    val description: String? = null,
    val iconEmoji: String = "⭐",
    val isPublic: Boolean = false,
    val publicShareId: String? = null,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis()
)

@Entity(
    tableName = "wishlist_items",
    primaryKeys = ["wishlistId", "productId"],
    foreignKeys = [
        ForeignKey(
            entity = Wishlist::class,
            parentColumns = ["id"],
            childColumns = ["wishlistId"],
            onDelete = ForeignKey.CASCADE
        ),
        ForeignKey(
            entity = Product::class,
            parentColumns = ["id"],
            childColumns = ["productId"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
data class WishlistItem(
    val wishlistId: String,
    val productId: String,
    val addedAt: Long = System.currentTimeMillis(),
    val sortOrder: Int = 0,
    val notes: String? = null  // Feature 48: Notes
)

@Dao
interface WishlistDao {

    // Feature 36: Get all wishlists
    @Query("SELECT * FROM wishlists WHERE userId = :userId ORDER BY createdAt DESC")
    fun getAllWishlists(userId: String): Flow<List<Wishlist>>

    // Feature 37: Get single wishlist
    @Query("SELECT * FROM wishlists WHERE id = :wishlistId")
    suspend fun getWishlist(wishlistId: String): Wishlist?

    // Feature 36: Create wishlist
    @Insert
    suspend fun insert(wishlist: Wishlist)

    // Feature 37: Rename wishlist
    @Update
    suspend fun update(wishlist: Wishlist)

    // Feature 37: Delete wishlist
    @Delete
    suspend fun delete(wishlist: Wishlist)

    // Feature 50: Get public wishlist by share ID
    @Query("SELECT * FROM wishlists WHERE publicShareId = :shareId")
    suspend fun getByShareId(shareId: String): Wishlist?
}

@Dao
interface WishlistItemDao {

    // Feature 41: Get all items in a wishlist
    @Query("""
        SELECT p.* FROM products p
        INNER JOIN wishlist_items wi ON p.id = wi.productId
        WHERE wi.wishlistId = :wishlistId
        ORDER BY wi.sortOrder, wi.addedAt DESC
    """)
    fun getProductsInWishlist(wishlistId: String): Flow<List<Product>>

    // Feature 38: Add product to wishlist
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(item: WishlistItem)

    // Feature 39: Remove product from wishlist
    @Query("DELETE FROM wishlist_items WHERE wishlistId = :wishlistId AND productId = :productId")
    suspend fun remove(wishlistId: String, productId: String)

    // Feature 40: Move product between wishlists
    @Query("UPDATE wishlist_items SET wishlistId = :toWishlistId WHERE wishlistId = :fromWishlistId AND productId = :productId")
    suspend fun moveProduct(productId: String, fromWishlistId: String, toWishlistId: String)

    // Feature 48: Update notes
    @Query("UPDATE wishlist_items SET notes = :notes WHERE wishlistId = :wishlistId AND productId = :productId")
    suspend fun updateNotes(wishlistId: String, productId: String, notes: String)

    // Feature 60: Calculate total cost
    @Query("""
        SELECT SUM(p.price) FROM products p
        INNER JOIN wishlist_items wi ON p.id = wi.productId
        WHERE wi.wishlistId = :wishlistId
    """)
    suspend fun getTotalCost(wishlistId: String): Double?

    // Feature 60: Get item count
    @Query("SELECT COUNT(*) FROM wishlist_items WHERE wishlistId = :wishlistId")
    suspend fun getItemCount(wishlistId: String): Int
}
```

#### **Day 3-4: Add Order Tracking Entities**

```kotlin
// mobile/android/app/src/main/java/aliexpress/companion/data/Order.kt

package aliexpress.companion.data

import androidx.room.*
import kotlinx.coroutines.flow.Flow
import java.util.UUID

// Features 61-80: Order and shipment tracking
@Entity(tableName = "orders")
data class Order(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val userId: String,
    val orderNumber: String,
    val trackingNumber: String? = null,
    val carrier: String? = null,
    val totalPrice: Double,
    val currency: String,
    val orderDate: Long,
    val status: OrderStatus,
    val lastStatusUpdate: Long = System.currentTimeMillis(),
    val estimatedDeliveryDate: Long? = null,
    val isDelivered: Boolean = false,
    val deliveredAt: Long? = null,
    val isArchived: Boolean = false,
    val notes: String? = null,
    val aliExpressOrderId: String? = null,
    val isAutoImported: Boolean = false,
    val sellerName: String? = null,
    val sellerContactUrl: String? = null
)

enum class OrderStatus {
    PROCESSING,
    SHIPPED,
    IN_TRANSIT,
    OUT_FOR_DELIVERY,
    DELIVERED,
    DELAYED,
    RETURNED,
    CANCELLED
}

@Entity(
    tableName = "order_items",
    primaryKeys = ["orderId", "productId"],
    foreignKeys = [
        ForeignKey(
            entity = Order::class,
            parentColumns = ["id"],
            childColumns = ["orderId"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
data class OrderItem(
    val orderId: String,
    val productId: String,
    val productName: String,
    val productImageUrl: String,
    val quantity: Int,
    val price: Double,
    val hasReviewed: Boolean = false  // Feature 77: Review reminder
)

@Entity(
    tableName = "tracking_events",
    foreignKeys = [
        ForeignKey(
            entity = Order::class,
            parentColumns = ["id"],
            childColumns = ["orderId"],
            onDelete = ForeignKey.CASCADE
        )
    ]
)
data class TrackingEvent(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val orderId: String,
    val status: String,
    val location: String? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val timestamp: Long,
    val description: String? = null
)

@Dao
interface OrderDao {

    // Feature 63: Get all orders
    @Query("SELECT * FROM orders WHERE userId = :userId AND isArchived = 0 ORDER BY orderDate DESC")
    fun getAllOrders(userId: String): Flow<List<Order>>

    // Feature 72: Filter by status
    @Query("SELECT * FROM orders WHERE userId = :userId AND status = :status AND isArchived = 0 ORDER BY orderDate DESC")
    fun getOrdersByStatus(userId: String, status: OrderStatus): Flow<List<Order>>

    // Feature 64: Get single order
    @Query("SELECT * FROM orders WHERE id = :orderId")
    suspend fun getOrder(orderId: String): Order?

    // Feature 61: Add order
    @Insert
    suspend fun insert(order: Order)

    // Feature 65: Update order status
    @Update
    suspend fun update(order: Order)

    // Feature 69: Mark as delivered
    @Query("UPDATE orders SET isDelivered = 1, deliveredAt = :timestamp WHERE id = :orderId")
    suspend fun markAsDelivered(orderId: String, timestamp: Long = System.currentTimeMillis())

    // Feature 70: Archive order
    @Query("UPDATE orders SET isArchived = 1 WHERE id = :orderId")
    suspend fun archive(orderId: String)

    // Feature 73: Update notes
    @Query("UPDATE orders SET notes = :notes WHERE id = :orderId")
    suspend fun updateNotes(orderId: String, notes: String)

    // Feature 62: Check if order exists
    @Query("SELECT COUNT(*) FROM orders WHERE aliExpressOrderId = :aliExpressId")
    suspend fun existsByAliExpressId(aliExpressId: String): Int
}

@Dao
interface OrderItemDao {

    @Query("SELECT * FROM order_items WHERE orderId = :orderId")
    fun getItemsForOrder(orderId: String): Flow<List<OrderItem>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(items: List<OrderItem>)

    // Feature 77: Check if reviewed
    @Query("UPDATE order_items SET hasReviewed = 1 WHERE orderId = :orderId AND productId = :productId")
    suspend fun markAsReviewed(orderId: String, productId: String)
}

@Dao
interface TrackingEventDao {

    // Feature 80: Get tracking timeline
    @Query("SELECT * FROM tracking_events WHERE orderId = :orderId ORDER BY timestamp DESC")
    fun getEventsForOrder(orderId: String): Flow<List<TrackingEvent>>

    @Insert
    suspend fun insert(event: TrackingEvent)

    @Insert
    suspend fun insertAll(events: List<TrackingEvent>)

    // Feature 74: Get latest location
    @Query("""
        SELECT * FROM tracking_events
        WHERE orderId = :orderId AND latitude IS NOT NULL AND longitude IS NOT NULL
        ORDER BY timestamp DESC LIMIT 1
    """)
    suspend fun getLatestLocation(orderId: String): TrackingEvent?
}
```

#### **Day 5: Update AppDatabase**

```kotlin
// mobile/android/app/src/main/java/aliexpress/companion/data/AppDatabase.kt

package aliexpress.companion.data

import android.content.Context
import androidx.room.*
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

@Database(
    entities = [
        // Shopping domain
        Product::class,
        PriceHistoryEntry::class,
        Wishlist::class,
        WishlistItem::class,
        Order::class,
        OrderItem::class,
        TrackingEvent::class,

        // User domain
        UserPreferences::class,
        UserInteraction::class
    ],
    version = 2,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {

    // Existing DAOs
    abstract fun productDao(): ProductDao
    abstract fun priceHistoryDao(): PriceHistoryDao
    abstract fun userPreferencesDao(): UserPreferencesDao
    abstract fun userInteractionDao(): UserInteractionDao

    // NEW DAOs
    abstract fun wishlistDao(): WishlistDao
    abstract fun wishlistItemDao(): WishlistItemDao
    abstract fun orderDao(): OrderDao
    abstract fun orderItemDao(): OrderItemDao
    abstract fun trackingEventDao(): TrackingEventDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "aliexpress_companion_database"
                )
                .addMigrations(MIGRATION_1_2)
                .build()
                INSTANCE = instance
                instance
            }
        }

        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(database: SupportSQLiteDatabase) {
                // Create wishlists table
                database.execSQL("""
                    CREATE TABLE IF NOT EXISTS wishlists (
                        id TEXT PRIMARY KEY NOT NULL,
                        userId TEXT NOT NULL,
                        name TEXT NOT NULL,
                        description TEXT,
                        iconEmoji TEXT NOT NULL,
                        isPublic INTEGER NOT NULL,
                        publicShareId TEXT,
                        createdAt INTEGER NOT NULL,
                        updatedAt INTEGER NOT NULL
                    )
                """)

                // Create wishlist_items table
                database.execSQL("""
                    CREATE TABLE IF NOT EXISTS wishlist_items (
                        wishlistId TEXT NOT NULL,
                        productId TEXT NOT NULL,
                        addedAt INTEGER NOT NULL,
                        sortOrder INTEGER NOT NULL,
                        notes TEXT,
                        PRIMARY KEY (wishlistId, productId),
                        FOREIGN KEY (wishlistId) REFERENCES wishlists(id) ON DELETE CASCADE,
                        FOREIGN KEY (productId) REFERENCES products(id) ON DELETE CASCADE
                    )
                """)

                // Create orders table
                database.execSQL("""
                    CREATE TABLE IF NOT EXISTS orders (
                        id TEXT PRIMARY KEY NOT NULL,
                        userId TEXT NOT NULL,
                        orderNumber TEXT NOT NULL,
                        trackingNumber TEXT,
                        carrier TEXT,
                        totalPrice REAL NOT NULL,
                        currency TEXT NOT NULL,
                        orderDate INTEGER NOT NULL,
                        status TEXT NOT NULL,
                        lastStatusUpdate INTEGER NOT NULL,
                        estimatedDeliveryDate INTEGER,
                        isDelivered INTEGER NOT NULL,
                        deliveredAt INTEGER,
                        isArchived INTEGER NOT NULL,
                        notes TEXT,
                        aliExpressOrderId TEXT,
                        isAutoImported INTEGER NOT NULL,
                        sellerName TEXT,
                        sellerContactUrl TEXT
                    )
                """)

                // Create order_items table
                database.execSQL("""
                    CREATE TABLE IF NOT EXISTS order_items (
                        orderId TEXT NOT NULL,
                        productId TEXT NOT NULL,
                        productName TEXT NOT NULL,
                        productImageUrl TEXT NOT NULL,
                        quantity INTEGER NOT NULL,
                        price REAL NOT NULL,
                        hasReviewed INTEGER NOT NULL,
                        PRIMARY KEY (orderId, productId),
                        FOREIGN KEY (orderId) REFERENCES orders(id) ON DELETE CASCADE
                    )
                """)

                // Create tracking_events table
                database.execSQL("""
                    CREATE TABLE IF NOT EXISTS tracking_events (
                        id TEXT PRIMARY KEY NOT NULL,
                        orderId TEXT NOT NULL,
                        status TEXT NOT NULL,
                        location TEXT,
                        latitude REAL,
                        longitude REAL,
                        timestamp INTEGER NOT NULL,
                        description TEXT,
                        FOREIGN KEY (orderId) REFERENCES orders(id) ON DELETE CASCADE
                    )
                """)
            }
        }
    }
}

class Converters {
    @TypeConverter
    fun fromOrderStatus(value: OrderStatus): String = value.name

    @TypeConverter
    fun toOrderStatus(value: String): OrderStatus = OrderStatus.valueOf(value)
}
```

---

### **Week 2: Option B - Add AI Features**

**Goal:** Deploy AI recommendation engine + 3 cloud agents
**Deliverables:** Intelligent product discovery, price predictions, review analysis

#### **Day 6-7: AI Recommendation Engine (Features 101-103)**

```kotlin
// mobile/android/app/src/main/java/aliexpress/companion/ai/RecommendationEngine.kt

package aliexpress.companion.ai

import android.content.Context
import org.tensorflow.lite.Interpreter
import java.nio.ByteBuffer
import java.nio.ByteOrder

class RecommendationEngine(context: Context) {

    private val interpreter: Interpreter

    init {
        // Load TensorFlow Lite model
        val model = loadModelFile(context, "recommendation_model.tflite")
        interpreter = Interpreter(model)
    }

    // Feature 101: Personalized recommendations
    suspend fun getRecommendations(
        userHistory: List<Product>,
        userPreferences: UserPreferences
    ): List<Product> {

        // Prepare input tensor
        val inputBuffer = prepareInputTensor(userHistory, userPreferences)

        // Run inference
        val outputBuffer = ByteBuffer.allocateDirect(4 * 100) // Top 100 products
        outputBuffer.order(ByteOrder.nativeOrder())

        interpreter.run(inputBuffer, outputBuffer)

        // Parse output
        return parseRecommendations(outputBuffer)
    }

    // Feature 102: Similar products
    suspend fun getSimilarProducts(product: Product): List<Product> {
        val productEmbedding = extractProductEmbedding(product)
        return findNearestNeighbors(productEmbedding, k = 10)
    }

    private fun prepareInputTensor(
        history: List<Product>,
        preferences: UserPreferences
    ): ByteBuffer {
        val buffer = ByteBuffer.allocateDirect(4 * 128) // 128 features
        buffer.order(ByteOrder.nativeOrder())

        // Encode user history
        history.takeLast(10).forEach { product ->
            buffer.putFloat(product.price.toFloat())
            buffer.putFloat(product.rating)
            // ... more features
        }

        // Encode preferences
        buffer.putFloat(preferences.budgetRange.first.toFloat())
        buffer.putFloat(preferences.budgetRange.second.toFloat())

        buffer.rewind()
        return buffer
    }

    private fun extractProductEmbedding(product: Product): FloatArray {
        // Use product features as embedding
        return floatArrayOf(
            product.price.toFloat(),
            product.rating,
            product.reviewCount.toFloat(),
            // ... more features
        )
    }

    private fun findNearestNeighbors(embedding: FloatArray, k: Int): List<Product> {
        // TODO: Implement k-NN search
        return emptyList()
    }

    private fun loadModelFile(context: Context, filename: String): ByteBuffer {
        val assetFileDescriptor = context.assets.openFd(filename)
        val inputStream = assetFileDescriptor.createInputStream()
        val fileChannel = inputStream.channel
        val startOffset = assetFileDescriptor.startOffset
        val declaredLength = assetFileDescriptor.declaredLength
        return fileChannel.map(java.nio.channels.FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
    }

    private fun parseRecommendations(buffer: ByteBuffer): List<Product> {
        // TODO: Parse output tensor into Product objects
        return emptyList()
    }
}
```

#### **Day 8-9: Price Prediction Agent (Feature 103)**

```kotlin
// agents/PricePredictionAgent.kt

package aliexpress.companion.agents

import aliexpress.companion.data.*
import aliexpress.companion.framework.LineageBus
import aliexpress.companion.framework.PerformanceMarket
import kotlinx.coroutines.*
import java.time.Instant
import java.time.temporal.ChronoUnit

class PricePredictionAgent(
    private val priceHistoryDao: PriceHistoryDao,
    private val lineageBus: LineageBus,
    private val performanceMarket: PerformanceMarket
) {

    private val scope = CoroutineScope(Dispatchers.Default + SupervisorJob())

    init {
        // Register with Performance Market
        performanceMarket.registerAgent(
            agentRole = "price-prediction-agent",
            capabilities = listOf(
                "price_forecasting",
                "trend_analysis",
                "drop_prediction"
            ),
            sla = SLA(
                p50Latency = 1000,
                successRate = 0.90
            ),
            costModel = CostModel(
                baseCost = 0.01,
                perRequestCost = 0.001
            )
        )
    }

    // Feature 103: Predict next price drop
    suspend fun predictNextPriceDrop(productId: String): PricePrediction {
        val startTime = System.currentTimeMillis()

        try {
            // Get price history
            val history = priceHistoryDao.getAllPricesSync(productId)

            if (history.size < 7) {
                return PricePrediction(
                    productId = productId,
                    confidence = 0.0,
                    predictedDropDate = null,
                    predictedPrice = null,
                    reason = "Insufficient data (need at least 7 days)"
                )
            }

            // Analyze trends
            val trends = analyzeTrends(history)
            val seasonality = detectSeasonality(history)
            val volatility = calculateVolatility(history)

            // Predict using simple linear regression + seasonality
            val prediction = if (trends.isDownward && volatility > 0.1) {
                val daysUntilDrop = estimateDaysUntilDrop(trends, seasonality)
                val predictedPrice = estimateDropPrice(history, trends)

                PricePrediction(
                    productId = productId,
                    confidence = calculateConfidence(history, trends),
                    predictedDropDate = Instant.now().plus(daysUntilDrop, ChronoUnit.DAYS).toEpochMilli(),
                    predictedPrice = predictedPrice,
                    reason = "Price trending downward with ${(volatility * 100).toInt()}% volatility"
                )
            } else {
                PricePrediction(
                    productId = productId,
                    confidence = 0.3,
                    predictedDropDate = null,
                    predictedPrice = null,
                    reason = "No strong downward trend detected"
                )
            }

            // Emit lineage event
            lineageBus.emitEvent(LineageEvent(
                eventType = "price_prediction_completed",
                agentRole = "price-prediction-agent",
                payload = mapOf(
                    "product_id" to productId,
                    "confidence" to prediction.confidence,
                    "processing_time_ms" to (System.currentTimeMillis() - startTime)
                )
            ))

            // Report to Performance Market
            performanceMarket.reportTaskCompletion(
                agentRole = "price-prediction-agent",
                taskType = "price_forecasting",
                success = true,
                latencyMs = (System.currentTimeMillis() - startTime).toInt()
            )

            return prediction

        } catch (e: Exception) {
            lineageBus.emitEvent(LineageEvent(
                eventType = "price_prediction_failed",
                agentRole = "price-prediction-agent",
                payload = mapOf("product_id" to productId, "error" to e.message.orEmpty())
            ))

            throw e
        }
    }

    private fun analyzeTrends(history: List<PriceHistoryEntry>): PriceTrend {
        val prices = history.map { it.price }
        val slope = calculateSlope(prices)

        return PriceTrend(
            isDownward = slope < -0.01,
            slope = slope,
            averagePrice = prices.average(),
            minPrice = prices.minOrNull() ?: 0.0,
            maxPrice = prices.maxOrNull() ?: 0.0
        )
    }

    private fun detectSeasonality(history: List<PriceHistoryEntry>): Seasonality {
        // Simple seasonality detection (weekly pattern)
        val dayOfWeekPrices = history.groupBy {
            Instant.ofEpochMilli(it.timestamp).atZone(java.time.ZoneId.systemDefault()).dayOfWeek
        }

        val bestDay = dayOfWeekPrices.minByOrNull { (_, entries) ->
            entries.map { it.price }.average()
        }?.key

        return Seasonality(
            hasClearPattern = dayOfWeekPrices.size >= 5,
            bestDayToBuy = bestDay?.value
        )
    }

    private fun calculateVolatility(history: List<PriceHistoryEntry>): Double {
        val prices = history.map { it.price }
        val mean = prices.average()
        val variance = prices.map { (it - mean) * (it - mean) }.average()
        return Math.sqrt(variance) / mean
    }

    private fun calculateSlope(prices: List<Double>): Double {
        val n = prices.size
        val x = (0 until n).map { it.toDouble() }
        val y = prices

        val xMean = x.average()
        val yMean = y.average()

        val numerator = x.zip(y).sumOf { (xi, yi) -> (xi - xMean) * (yi - yMean) }
        val denominator = x.sumOf { (it - xMean) * (it - xMean) }

        return if (denominator != 0.0) numerator / denominator else 0.0
    }

    private fun estimateDaysUntilDrop(trend: PriceTrend, seasonality: Seasonality): Long {
        return if (seasonality.hasClearPattern && seasonality.bestDayToBuy != null) {
            // Next occurrence of best day
            val today = Instant.now().atZone(java.time.ZoneId.systemDefault()).dayOfWeek.value
            val targetDay = seasonality.bestDayToBuy
            ((targetDay - today + 7) % 7).toLong()
        } else {
            // Estimate based on trend
            (7..14).random().toLong()
        }
    }

    private fun estimateDropPrice(history: List<PriceHistoryEntry>, trend: PriceTrend): Double {
        val currentPrice = history.last().price
        val dropPercentage = 0.05 + (Math.abs(trend.slope) * 0.1)
        return currentPrice * (1 - dropPercentage)
    }

    private fun calculateConfidence(history: List<PriceHistoryEntry>, trend: PriceTrend): Double {
        val dataQuality = minOf(history.size / 30.0, 1.0)
        val trendStrength = minOf(Math.abs(trend.slope) * 10, 1.0)
        return (dataQuality + trendStrength) / 2
    }
}

data class PricePrediction(
    val productId: String,
    val confidence: Double,
    val predictedDropDate: Long?,
    val predictedPrice: Double?,
    val reason: String
)

data class PriceTrend(
    val isDownward: Boolean,
    val slope: Double,
    val averagePrice: Double,
    val minPrice: Double,
    val maxPrice: Double
)

data class Seasonality(
    val hasClearPattern: Boolean,
    val bestDayToBuy: Int?
)
```

#### **Day 10: Review Analysis Agent (Feature 104)**

```kotlin
// agents/ReviewAnalysisAgent.kt

package aliexpress.companion.agents

import aliexpress.companion.ai.SentimentModel
import aliexpress.companion.framework.LineageBus
import aliexpress.companion.framework.PerformanceMarket

class ReviewAnalysisAgent(
    private val sentimentModel: SentimentModel,
    private val lineageBus: LineageBus,
    private val performanceMarket: PerformanceMarket
) {

    // Feature 104: Summarize reviews (pros and cons)
    suspend fun summarizeReviews(reviews: List<Review>): ReviewSummary {

        val positiveReviews = reviews.filter { it.rating >= 4 }
        val negativeReviews = reviews.filter { it.rating <= 2 }

        // Extract common themes
        val pros = extractCommonThemes(positiveReviews)
        val cons = extractCommonThemes(negativeReviews)

        // Sentiment analysis
        val overallSentiment = reviews.map {
            sentimentModel.analyzeSentiment(it.content)
        }.average()

        return ReviewSummary(
            totalReviews = reviews.size,
            averageRating = reviews.map { it.rating }.average(),
            pros = pros.take(5),
            cons = cons.take(5),
            overallSentiment = overallSentiment,
            recommendationScore = calculateRecommendationScore(reviews)
        )
    }

    private fun extractCommonThemes(reviews: List<Review>): List<String> {
        // Simple keyword extraction
        val allWords = reviews.flatMap { review ->
            review.content.lowercase()
                .split(Regex("\\W+"))
                .filter { it.length > 4 }
        }

        return allWords
            .groupingBy { it }
            .eachCount()
            .entries
            .sortedByDescending { it.value }
            .take(10)
            .map { it.key }
    }

    private fun calculateRecommendationScore(reviews: List<Review>): Double {
        val ratingScore = reviews.map { it.rating }.average() / 5.0
        val volumeScore = minOf(reviews.size / 100.0, 1.0)
        return (ratingScore * 0.7 + volumeScore * 0.3)
    }
}

data class Review(
    val id: String,
    val rating: Int,
    val content: String,
    val authorName: String,
    val timestamp: Long
)

data class ReviewSummary(
    val totalReviews: Int,
    val averageRating: Double,
    val pros: List<String>,
    val cons: List<String>,
    val overallSentiment: Double,
    val recommendationScore: Double
)
```

---

### **Week 3: Build UI Screens (Features 36-80)**

**Goal:** Create 6 core screens with Material 3 design
**Deliverables:** Complete user-facing interface

#### **Day 11-12: Wishlist Screen**

```kotlin
// ui/screens/shopping/WishlistScreen.kt

@Composable
fun WishlistScreen(
    viewModel: WishlistViewModel = viewModel(),
    onNavigateToProduct: (String) -> Unit
) {
    val wishlists by viewModel.wishlists.collectAsState()
    val selectedWishlist by viewModel.selectedWishlist.collectAsState()
    val products by viewModel.productsInSelectedWishlist.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(selectedWishlist?.name ?: "My Wishlists") },
                actions = {
                    IconButton(onClick = { viewModel.showCreateWishlistDialog() }) {
                        Icon(Icons.Filled.Add, "Create Wishlist")
                    }
                }
            )
        }
    ) { padding ->
        Row(modifier = Modifier.padding(padding)) {

            // Left: Wishlist tabs
            Column(
                modifier = Modifier
                    .width(100.dp)
                    .fillMaxHeight()
                    .background(MaterialTheme.colorScheme.surfaceVariant)
            ) {
                wishlists.forEach { wishlist ->
                    WishlistTab(
                        wishlist = wishlist,
                        isSelected = wishlist.id == selectedWishlist?.id,
                        onClick = { viewModel.selectWishlist(wishlist.id) }
                    )
                }
            }

            // Right: Products
            LazyColumn(modifier = Modifier.weight(1f)) {

                // Summary card
                item {
                    WishlistSummaryCard(
                        itemCount = products.size,
                        totalCost = viewModel.calculateTotalCost(),
                        onShareClick = { viewModel.shareWishlist() }
                    )
                }

                // Products
                items(products) { product ->
                    ProductCard(
                        product = product,
                        onClick = { onNavigateToProduct(product.id) },
                        onRemove = { viewModel.removeFromWishlist(product.id) }
                    )
                }
            }
        }
    }
}
```

#### **Day 13-14: Orders Screen**

```kotlin
// ui/screens/shopping/OrdersScreen.kt

@Composable
fun OrdersScreen(
    viewModel: OrderViewModel = viewModel(),
    onNavigateToOrderDetail: (String) -> Unit
) {
    val orders by viewModel.orders.collectAsState()
    val selectedTab by viewModel.selectedTab.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("My Orders") },
                actions = {
                    IconButton(onClick = { viewModel.showAddOrderDialog() }) {
                        Icon(Icons.Filled.Add, "Add Order")
                    }
                }
            )
        }
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {

            // Status tabs
            ScrollableTabRow(selectedTabIndex = selectedTab) {
                Tab(
                    selected = selectedTab == 0,
                    onClick = { viewModel.selectTab(0) },
                    text = { Text("All") }
                )
                Tab(
                    selected = selectedTab == 1,
                    onClick = { viewModel.selectTab(1) },
                    text = { Text("Processing") }
                )
                Tab(
                    selected = selectedTab == 2,
                    onClick = { viewModel.selectTab(2) },
                    text = { Text("Shipped") }
                )
                Tab(
                    selected = selectedTab == 3,
                    onClick = { viewModel.selectTab(3) },
                    text = { Text("Delivered") }
                )
            }

            // Orders list
            LazyColumn {
                items(orders) { order ->
                    OrderCard(
                        order = order,
                        onClick = { onNavigateToOrderDetail(order.id) }
                    )
                }
            }
        }
    }
}
```

---

### **Week 4: Option A - Launch MVP**

**Goal:** Beta launch with 50 core features
**Deliverables:** 1,000 users, $10K/month revenue

#### **Day 15-16: Final Integration & Testing**

- [ ] Test all database migrations
- [ ] Test AI recommendation engine
- [ ] Test price prediction accuracy
- [ ] Test order tracking with real carriers
- [ ] Performance testing (app startup time, search latency)
- [ ] Battery drain testing
- [ ] Memory leak testing

#### **Day 17-18: Beta Launch Preparation**

- [ ] Set up Firebase Analytics
- [ ] Configure crash reporting (Firebase Crashlytics)
- [ ] Set up A/B testing framework
- [ ] Create onboarding flow
- [ ] Write app store listing (Google Play)
- [ ] Create promotional screenshots
- [ ] Set up affiliate tracking links

#### **Day 19-20: Soft Launch**

- [ ] Deploy to Google Play (closed beta track)
- [ ] Invite 100 alpha testers
- [ ] Monitor crash rate (target: <1%)
- [ ] Monitor ANR rate (target: <0.5%)
- [ ] Collect feedback via in-app surveys
- [ ] Fix critical bugs

#### **Day 21-28: Scale to 1,000 Users**

- [ ] Open beta to public (still beta track)
- [ ] Run Reddit ads ($500 budget)
- [ ] Post on Product Hunt
- [ ] Reach out to tech influencers
- [ ] Monitor daily active users (DAU)
- [ ] Track affiliate conversions
- [ ] Iterate based on feedback

---

## 📊 Success Metrics

### **Week 1 (Foundation)**

- ✅ 3 new entities added to database
- ✅ 9 new DAOs implemented
- ✅ Database migration tested
- ✅ All unit tests passing

### **Week 2 (AI)**

- ✅ Recommendation engine deployed
- ✅ Price prediction accuracy >70%
- ✅ Review summarization working
- ✅ 3 cloud agents registered with Performance Market

### **Week 3 (UI)**

- ✅ 6 core screens completed
- ✅ Material 3 design system implemented
- ✅ App navigation tested
- ✅ <2 second screen load time

### **Week 4 (Launch)**

- 🎯 100 alpha testers (Day 20)
- 🎯 1,000 beta users (Day 28)
- 🎯 4.0+ star rating on Google Play
- 🎯 $10K/month in affiliate revenue
- 🎯 <1% crash rate
- 🎯 60% day-1 retention

---

## 🚀 What's Next After Week 4?

### **Month 2: Scale to 10K Users**

- Add community features (reviews, collections)
- Implement gamification (points, levels)
- Launch web version
- Reach $50K/month revenue

### **Month 3: Scale to 100K Users**

- Multi-platform support (Amazon, eBay)
- Premium subscription tier ($4.99/month)
- Advanced analytics dashboard
- Reach $200K/month revenue

### **Month 4-6: Path to 1M Users**

- Developer API launch
- B2B features for dropshippers
- International expansion (Europe, Asia)
- Reach $1M/month revenue

---

## ✅ Immediate Next Steps

**This Week (Week 1):**

1. **Today:** Create `Wishlist.kt` entity (Day 1)
2. **Tomorrow:** Create `Order.kt` entity (Day 3)
3. **Day 3:** Update `AppDatabase.kt` with migration (Day 5)
4. **Day 4:** Test database migration
5. **Day 5:** Code review and refactoring

**Ready to start coding?** 🚀

