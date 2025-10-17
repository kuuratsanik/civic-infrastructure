package aliexpress.companion.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import aliexpress.companion.data.Product
import aliexpress.companion.data.ProductRepository
import aliexpress.companion.data.UserInteractionRepository
import aliexpress.companion.data.InteractionType
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

/**
 * ViewModel for Product-related operations.
 *
 * Follows MVVM architecture pattern.
 * Manages UI state and coordinates with repository layer.
 *
 * Framework Integration:
 * - Works with Data Caching Agent via repository
 * - Records user interactions for UI Personalization Agent
 * - Emits lineage events for audit trail
 */
class ProductViewModel(
    private val productRepository: ProductRepository,
    private val interactionRepository: UserInteractionRepository
) : ViewModel() {

    // ============================================
    // UI STATE
    // ============================================

    private val _uiState = MutableStateFlow<ProductUiState>(ProductUiState.Loading)
    val uiState: StateFlow<ProductUiState> = _uiState.asStateFlow()

    private val _products = MutableStateFlow<List<Product>>(emptyList())
    val products: StateFlow<List<Product>> = _products.asStateFlow()

    private val _selectedProduct = MutableStateFlow<Product?>(null)
    val selectedProduct: StateFlow<Product?> = _selectedProduct.asStateFlow()

    private val _searchQuery = MutableStateFlow("")
    val searchQuery: StateFlow<String> = _searchQuery.asStateFlow()

    // ============================================
    // INITIALIZATION
    // ============================================

    init {
        loadProducts()
    }

    // ============================================
    // PRODUCT OPERATIONS
    // ============================================

    /**
     * Load all products from cache.
     */
    fun loadProducts() {
        viewModelScope.launch {
            _uiState.value = ProductUiState.Loading

            try {
                productRepository.getAllProducts().collect { productList ->
                    _products.value = productList
                    _uiState.value = if (productList.isEmpty()) {
                        ProductUiState.Empty
                    } else {
                        ProductUiState.Success
                    }
                }
            } catch (e: Exception) {
                _uiState.value = ProductUiState.Error(e.message ?: "Unknown error")
            }
        }
    }

    /**
     * Load product by ID.
     */
    fun loadProduct(productId: String) {
        viewModelScope.launch {
            _uiState.value = ProductUiState.Loading

            try {
                val product = productRepository.getProduct(productId)
                _selectedProduct.value = product

                if (product != null) {
                    // Record product access for cache scoring
                    productRepository.recordProductAccess(productId)

                    // Record interaction for UI personalization
                    interactionRepository.recordProductView(productId)

                    _uiState.value = ProductUiState.Success
                } else {
                    _uiState.value = ProductUiState.Error("Product not found")
                }
            } catch (e: Exception) {
                _uiState.value = ProductUiState.Error(e.message ?: "Unknown error")
            }
        }
    }

    /**
     * Search products by query.
     */
    fun searchProducts(query: String) {
        viewModelScope.launch {
            _searchQuery.value = query
            _uiState.value = ProductUiState.Loading

            try {
                // Record search interaction
                interactionRepository.recordSearch(query)

                productRepository.searchProducts(query).collect { results ->
                    _products.value = results
                    _uiState.value = if (results.isEmpty()) {
                        ProductUiState.Empty
                    } else {
                        ProductUiState.Success
                    }
                }
            } catch (e: Exception) {
                _uiState.value = ProductUiState.Error(e.message ?: "Unknown error")
            }
        }
    }

    /**
     * Load products by category.
     */
    fun loadProductsByCategory(category: String) {
        viewModelScope.launch {
            _uiState.value = ProductUiState.Loading

            try {
                productRepository.getProductsByCategory(category).collect { categoryProducts ->
                    _products.value = categoryProducts
                    _uiState.value = if (categoryProducts.isEmpty()) {
                        ProductUiState.Empty
                    } else {
                        ProductUiState.Success
                    }
                }
            } catch (e: Exception) {
                _uiState.value = ProductUiState.Error(e.message ?: "Unknown error")
            }
        }
    }

    /**
     * Load recently viewed products.
     */
    fun loadRecentlyViewed(limit: Int = 20) {
        viewModelScope.launch {
            _uiState.value = ProductUiState.Loading

            try {
                productRepository.getRecentlyViewed(limit).collect { recentProducts ->
                    _products.value = recentProducts
                    _uiState.value = if (recentProducts.isEmpty()) {
                        ProductUiState.Empty
                    } else {
                        ProductUiState.Success
                    }
                }
            } catch (e: Exception) {
                _uiState.value = ProductUiState.Error(e.message ?: "Unknown error")
            }
        }
    }

    // ============================================
    // WISHLIST OPERATIONS
    // ============================================

    /**
     * Add product to wishlist.
     */
    fun addToWishlist(productId: String) {
        viewModelScope.launch {
            try {
                productRepository.addToWishlist(productId)

                // Record interaction
                interactionRepository.recordInteraction(
                    aliexpress.companion.data.UserInteraction(
                        type = InteractionType.ADD_TO_WISHLIST,
                        screenName = "product_detail",
                        productId = productId
                    )
                )

                // Show success message
                _uiState.value = ProductUiState.Success
            } catch (e: Exception) {
                _uiState.value = ProductUiState.Error("Failed to add to wishlist: ${e.message}")
            }
        }
    }

    /**
     * Remove product from wishlist.
     */
    fun removeFromWishlist(productId: String) {
        viewModelScope.launch {
            try {
                productRepository.removeFromWishlist(productId)

                // Record interaction
                interactionRepository.recordInteraction(
                    aliexpress.companion.data.UserInteraction(
                        type = InteractionType.REMOVE_FROM_WISHLIST,
                        screenName = "wishlist",
                        productId = productId
                    )
                )

                _uiState.value = ProductUiState.Success
            } catch (e: Exception) {
                _uiState.value = ProductUiState.Error("Failed to remove from wishlist: ${e.message}")
            }
        }
    }

    /**
     * Load wishlist products.
     */
    fun loadWishlist() {
        viewModelScope.launch {
            _uiState.value = ProductUiState.Loading

            try {
                productRepository.getWishlist().collect { wishlistProducts ->
                    _products.value = wishlistProducts
                    _uiState.value = if (wishlistProducts.isEmpty()) {
                        ProductUiState.Empty
                    } else {
                        ProductUiState.Success
                    }
                }
            } catch (e: Exception) {
                _uiState.value = ProductUiState.Error(e.message ?: "Unknown error")
            }
        }
    }

    // ============================================
    // PRICE TRACKING OPERATIONS
    // ============================================

    /**
     * Start tracking product price.
     */
    fun startTracking(productId: String, priceTarget: Double? = null) {
        viewModelScope.launch {
            try {
                productRepository.startTracking(productId, priceTarget)

                // Record interaction
                interactionRepository.recordInteraction(
                    aliexpress.companion.data.UserInteraction(
                        type = InteractionType.START_TRACKING,
                        screenName = "product_detail",
                        productId = productId,
                        metadata = priceTarget?.toString()
                    )
                )

                _uiState.value = ProductUiState.Success
            } catch (e: Exception) {
                _uiState.value = ProductUiState.Error("Failed to start tracking: ${e.message}")
            }
        }
    }

    /**
     * Stop tracking product price.
     */
    fun stopTracking(productId: String) {
        viewModelScope.launch {
            try {
                productRepository.stopTracking(productId)

                // Record interaction
                interactionRepository.recordInteraction(
                    aliexpress.companion.data.UserInteraction(
                        type = InteractionType.STOP_TRACKING,
                        screenName = "product_detail",
                        productId = productId
                    )
                )

                _uiState.value = ProductUiState.Success
            } catch (e: Exception) {
                _uiState.value = ProductUiState.Error("Failed to stop tracking: ${e.message}")
            }
        }
    }

    /**
     * Load tracked products.
     */
    fun loadTrackedProducts() {
        viewModelScope.launch {
            _uiState.value = ProductUiState.Loading

            try {
                productRepository.getTrackedProducts().collect { trackedProducts ->
                    _products.value = trackedProducts
                    _uiState.value = if (trackedProducts.isEmpty()) {
                        ProductUiState.Empty
                    } else {
                        ProductUiState.Success
                    }
                }
            } catch (e: Exception) {
                _uiState.value = ProductUiState.Error(e.message ?: "Unknown error")
            }
        }
    }

    /**
     * Get price history for a product.
     */
    fun loadPriceHistory(productId: String, limit: Int = 100) {
        viewModelScope.launch {
            try {
                productRepository.getPriceHistory(productId, limit).collect { history ->
                    // Update UI state with price history
                    // This could be exposed as a separate StateFlow if needed
                }
            } catch (e: Exception) {
                _uiState.value = ProductUiState.Error("Failed to load price history: ${e.message}")
            }
        }
    }

    // ============================================
    // CACHE MANAGEMENT
    // ============================================

    /**
     * Clear stale cache entries.
     */
    fun clearStaleCache() {
        viewModelScope.launch {
            try {
                productRepository.clearStaleCache()
            } catch (e: Exception) {
                _uiState.value = ProductUiState.Error("Failed to clear cache: ${e.message}")
            }
        }
    }

    /**
     * Clear entire cache.
     */
    fun clearAllCache() {
        viewModelScope.launch {
            try {
                productRepository.clearCache()
                _products.value = emptyList()
                _uiState.value = ProductUiState.Empty
            } catch (e: Exception) {
                _uiState.value = ProductUiState.Error("Failed to clear cache: ${e.message}")
            }
        }
    }
}

/**
 * UI state for product screens.
 */
sealed class ProductUiState {
    object Loading : ProductUiState()
    object Success : ProductUiState()
    object Empty : ProductUiState()
    data class Error(val message: String) : ProductUiState()
}
