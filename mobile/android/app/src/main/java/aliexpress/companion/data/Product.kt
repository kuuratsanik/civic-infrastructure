package aliexpress.companion.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.Date

/**
 * Product data model representing an AliExpress product.
 *
 * This model is used throughout the application and is persisted
 * locally by the Data Caching Agent (Phase 1).
 *
 * Framework Integration:
 * - Cached locally via Room database (Data Caching Agent)
 * - Tracked for price changes by Price Tracking Agent (Phase 2)
 * - Used by UI Personalization Agent for recommendations
 */
@Entity(tableName = "products")
data class Product(
    @PrimaryKey
    val id: String,

    val name: String,

    val price: Double,

    val currency: String = "USD",

    val imageUrl: String,

    val productUrl: String,

    val description: String? = null,

    val category: String? = null,

    val sellerId: String? = null,

    val sellerName: String? = null,

    val rating: Float? = null,

    val reviewCount: Int = 0,

    val shippingCost: Double? = null,

    val estimatedDeliveryDays: Int? = null,

    // Caching metadata
    val cachedAt: Long = System.currentTimeMillis(),

    val lastAccessedAt: Long = System.currentTimeMillis(),

    val accessCount: Int = 0,

    val cacheScore: Float = 0.5f, // ML-predicted cache value

    // Tracking metadata
    val isTracked: Boolean = false,

    val trackingStartedAt: Long? = null,

    val priceTarget: Double? = null, // User's desired price

    // Wish list metadata
    val isInWishlist: Boolean = false,

    val addedToWishlistAt: Long? = null
) {
    /**
     * Calculate the display price with currency symbol.
     */
    fun getDisplayPrice(): String {
        return when (currency) {
            "USD" -> "$$price"
            "EUR" -> "€$price"
            "GBP" -> "£$price"
            else -> "$currency $price"
        }
    }

    /**
     * Calculate cache age in hours.
     */
    fun getCacheAgeHours(): Long {
        return (System.currentTimeMillis() - cachedAt) / (1000 * 60 * 60)
    }

    /**
     * Determine if cache is stale (older than 24 hours).
     */
    fun isCacheStale(): Boolean {
        return getCacheAgeHours() > 24
    }

    /**
     * Check if product is eligible for price drop alert.
     */
    fun shouldAlertOnPriceDrop(newPrice: Double): Boolean {
        if (!isTracked) return false

        // Alert if price dropped by 10% or more
        val dropPercent = ((price - newPrice) / price) * 100
        if (dropPercent >= 10) return true

        // Alert if price dropped below user's target
        if (priceTarget != null && newPrice <= priceTarget) return true

        return false
    }

    /**
     * Create a copy with updated access metadata.
     * Used by Data Caching Agent to track product usage.
     */
    fun withAccessRecorded(): Product {
        return copy(
            lastAccessedAt = System.currentTimeMillis(),
            accessCount = accessCount + 1
        )
    }

    /**
     * Create a copy with updated cache score.
     * Used by Data Caching Agent's ML model.
     */
    fun withCacheScore(score: Float): Product {
        return copy(cacheScore = score)
    }
}

/**
 * Price history entry for trend analysis.
 */
@Entity(tableName = "price_history")
data class PriceHistoryEntry(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,

    val productId: String,

    val price: Double,

    val currency: String,

    val timestamp: Long = System.currentTimeMillis()
) {
    /**
     * Calculate price change from a previous entry.
     */
    fun calculateChange(previousPrice: Double): PriceChange {
        val difference = price - previousPrice
        val percentChange = (difference / previousPrice) * 100

        return PriceChange(
            difference = difference,
            percentChange = percentChange,
            direction = when {
                difference > 0 -> PriceDirection.UP
                difference < 0 -> PriceDirection.DOWN
                else -> PriceDirection.STABLE
            }
        )
    }
}

/**
 * Price change calculation result.
 */
data class PriceChange(
    val difference: Double,
    val percentChange: Double,
    val direction: PriceDirection
)

/**
 * Price change direction.
 */
enum class PriceDirection {
    UP,
    DOWN,
    STABLE
}

/**
 * Order tracking data model.
 */
@Entity(tableName = "orders")
data class Order(
    @PrimaryKey
    val orderId: String,

    val productIds: List<String>, // Comma-separated

    val totalAmount: Double,

    val currency: String = "USD",

    val orderDate: Long,

    val status: OrderStatus,

    val trackingNumber: String? = null,

    val carrier: String? = null,

    val estimatedDelivery: Long? = null,

    val shippingAddress: String? = null,

    val lastUpdateAt: Long = System.currentTimeMillis()
) {
    /**
     * Get display-friendly status text.
     */
    fun getStatusText(): String {
        return when (status) {
            OrderStatus.PENDING -> "Order Pending"
            OrderStatus.PROCESSING -> "Processing Order"
            OrderStatus.SHIPPED -> "Shipped"
            OrderStatus.IN_TRANSIT -> "In Transit"
            OrderStatus.OUT_FOR_DELIVERY -> "Out for Delivery"
            OrderStatus.DELIVERED -> "Delivered"
            OrderStatus.CANCELLED -> "Cancelled"
            OrderStatus.REFUNDED -> "Refunded"
        }
    }

    /**
     * Calculate days until estimated delivery.
     */
    fun getDaysUntilDelivery(): Int? {
        if (estimatedDelivery == null) return null

        val now = System.currentTimeMillis()
        val daysRemaining = ((estimatedDelivery - now) / (1000 * 60 * 60 * 24)).toInt()

        return maxOf(0, daysRemaining)
    }
}

/**
 * Order status enumeration.
 */
enum class OrderStatus {
    PENDING,
    PROCESSING,
    SHIPPED,
    IN_TRANSIT,
    OUT_FOR_DELIVERY,
    DELIVERED,
    CANCELLED,
    REFUNDED
}

/**
 * User preferences for UI Personalization Agent.
 */
@Entity(tableName = "user_preferences")
data class UserPreferences(
    @PrimaryKey
    val userId: String = "default",

    val theme: String = "light", // "light", "dark", "auto"

    val fontSize: Int = 14,

    val density: String = "normal", // "compact", "normal", "comfortable"

    val layout: String = "grid", // "grid", "list"

    val language: String = "en",

    val currency: String = "USD",

    // Notification preferences
    val enablePriceDropNotifications: Boolean = true,

    val enableDealNotifications: Boolean = true,

    val enableShippingNotifications: Boolean = true,

    val enableRecommendationNotifications: Boolean = false,

    val enableMarketingNotifications: Boolean = false,

    // Do Not Disturb schedule
    val dndEnabled: Boolean = false,

    val dndStartHour: Int = 22, // 10 PM

    val dndEndHour: Int = 8,    // 8 AM

    // Privacy settings
    val enableAnalytics: Boolean = true,

    val enablePersonalization: Boolean = true,

    val shareDataWithCloud: Boolean = true,

    val lastUpdatedAt: Long = System.currentTimeMillis()
)

/**
 * User interaction tracking for UI Personalization Agent.
 */
@Entity(tableName = "user_interactions")
data class UserInteraction(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,

    val type: InteractionType,

    val screenName: String,

    val action: String? = null,

    val productId: String? = null,

    val duration: Long = 0, // milliseconds

    val timestamp: Long = System.currentTimeMillis(),

    val metadata: String? = null // JSON-encoded additional data
)

/**
 * Interaction type enumeration.
 */
enum class InteractionType {
    SCREEN_VIEW,
    PRODUCT_VIEW,
    PRODUCT_CLICK,
    ADD_TO_WISHLIST,
    REMOVE_FROM_WISHLIST,
    START_TRACKING,
    STOP_TRACKING,
    SHARE_PRODUCT,
    SEARCH,
    FILTER_APPLIED,
    SORT_CHANGED,
    NOTIFICATION_CLICKED,
    NOTIFICATION_DISMISSED
}
