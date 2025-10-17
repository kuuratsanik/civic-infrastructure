package aliexpress.companion.data

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters

/**
 * Main Room database for the AliExpress Companion app.
 *
 * This database serves as the local cache managed by the Data Caching Agent.
 * All data is stored on-device for privacy and offline access.
 *
 * Framework Integration:
 * - Managed by Data Caching Agent (Phase 1)
 * - Provides offline-first architecture
 * - Enables reactive data updates via Flow
 * - Supports ML-based cache eviction strategies
 */
@Database(
    entities = [
        Product::class,
        PriceHistoryEntry::class,
        Order::class,
        UserPreferences::class,
        UserInteraction::class
    ],
    version = 1,
    exportSchema = true
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {

    abstract fun productDao(): ProductDao
    abstract fun priceHistoryDao(): PriceHistoryDao
    abstract fun orderDao(): OrderDao
    abstract fun userPreferencesDao(): UserPreferencesDao
    abstract fun userInteractionDao(): UserInteractionDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        private const val DATABASE_NAME = "aliexpress_companion.db"

        /**
         * Get singleton database instance.
         * Thread-safe with double-checked locking.
         */
        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    DATABASE_NAME
                )
                    .fallbackToDestructiveMigration() // For development
                    .build()

                INSTANCE = instance
                instance
            }
        }

        /**
         * Close database (for testing or cleanup).
         */
        fun closeDatabase() {
            INSTANCE?.close()
            INSTANCE = null
        }
    }
}

/**
 * Type converters for Room database.
 * Handles conversion of complex types to/from database primitives.
 */
class Converters {

    /**
     * Convert OrderStatus enum to String.
     */
    @androidx.room.TypeConverter
    fun fromOrderStatus(status: OrderStatus): String {
        return status.name
    }

    /**
     * Convert String to OrderStatus enum.
     */
    @androidx.room.TypeConverter
    fun toOrderStatus(value: String): OrderStatus {
        return OrderStatus.valueOf(value)
    }

    /**
     * Convert InteractionType enum to String.
     */
    @androidx.room.TypeConverter
    fun fromInteractionType(type: InteractionType): String {
        return type.name
    }

    /**
     * Convert String to InteractionType enum.
     */
    @androidx.room.TypeConverter
    fun toInteractionType(value: String): InteractionType {
        return InteractionType.valueOf(value)
    }

    /**
     * Convert List<String> to String (comma-separated).
     */
    @androidx.room.TypeConverter
    fun fromStringList(list: List<String>): String {
        return list.joinToString(",")
    }

    /**
     * Convert String (comma-separated) to List<String>.
     */
    @androidx.room.TypeConverter
    fun toStringList(value: String): List<String> {
        return if (value.isEmpty()) {
            emptyList()
        } else {
            value.split(",")
        }
    }
}
