# datul_advmobprogAY2627

## Lab Activity 2: API Integration & Architecture

### Laboratory Discussion

#### 1. Interaction between Model, Service, and Screen to Render the API Endpoint

In this activity, the application communicates with an external REST API endpoint (`https://dummyjson.com/products`) using a decoupled three-tier workflow:

1. **Service Layer (`ProductService`)**:
   - The service layer encapsulates all network communication and HTTP protocol handling.
   - Using the `http` package and `flutter_dotenv`, `ProductService.getAllProducts()` performs an asynchronous HTTP GET request to `Uri.parse('$host/products')`.
   - Upon receiving the HTTP response with status code `200 OK`, it uses `jsonDecode()` from `dart:convert` to deserialize the JSON string into Dart `Map<String, dynamic>`.
   - It extracts the `products` list and iterates through each item, delegating object construction to the model layer via `Product.fromJson(json)`.
   - The result is returned as a `Future<List<Product>>`. If the response fails, it throws a meaningful exception.

2. **Model Layer (`Product`, `ProductDimensions`, `ProductReview`, `ProductMeta`)**:
   - The model acts as the data blueprint and contract between the backend API and the Flutter front-end.
   - The factory constructor `Product.fromJson(Map<String, dynamic> json)` enforces strong typing, type safety, and null safety with fallback default values.
   - It handles complex nested structures, including dimensions, reviews, and metadata, converting untyped JSON dictionaries into immutable, strongly-typed Dart objects.

3. **Screen / Presentation Layer (`ProductScreen`, `ProductDetailScreen`, `HomeScreen`)**:
   - In `ProductScreen`, `_productsFuture` is initialized in `initState()` by calling `ProductService().getAllProducts()`.
   - A `FutureBuilder<List<Product>>` listens to the asynchronous lifecycle of the future:
     - **Waiting State (`ConnectionState.waiting`)**: Displays a `CircularProgressIndicator`.
     - **Error State (`snapshot.hasError`)**: Gracefully renders error messaging to the user.
     - **Success State**: Extracts `snapshot.data` and renders an interactive, responsive `GridView.builder` with product cards.
   - When a user interacts with the search bar, the UI dynamically filters the loaded product models by title, category, or brand in real time.
   - Clicking on a product card navigates to `ProductDetailScreen`, directly passing the selected `Product` instance for rich detailed presentation without unnecessary redundant API calls.

---

#### 2. Architectural Design Pattern

This activity implements a **Layered Architecture (Separation of Concerns / Service-Repository Pattern)** combined with the **Provider / Observer Pattern**:

1. **Separation of Concerns (SoC)**:
   - **`models/`**: Responsible only for data structures and serialization/deserialization.
   - **`services/`**: Responsible only for remote networking, API interactions, and business data retrieval.
   - **`providers/`**: Responsible for global application state management (`ThemeProvider`).
   - **`widgets/` & `screens/`**: Responsible only for UI layout, styling, and user interaction.
   - *Benefits*: High modularity, testability, maintainability, and clean code organization. Any modification in the API format only requires changes in the Model and Service layers without affecting the UI design.

2. **Observer / Provider Pattern**:
   - `ThemeProvider` extends `ChangeNotifier`. When a theme change is triggered from `SettingsScreen` via `toggleTheme()`, `notifyListeners()` broadcasts the event to listening widgets.
   - `ScreenUtilInit` and `MaterialApp` reactively rebuild, seamlessly toggling between Light and Dark mode across the entire app.

---

### Implemented Enhancements

- **Enhancement 1: Real-time Search Bar**: Added an interactive search text input above the product grid that filters items in real time by product title, brand, or category with instant feedback.
- **Enhancement 2: Comprehensive Product Details Screen**: Implemented `ProductDetailScreen` opened on product card tap, featuring the product image card, ratings, price with discount tag, stock status, full description, warranty, shipping, and customer reviews.
- **Enhancement 3: Settings Screen with Theme Switch**: Added a dedicated `SettingsScreen` accessible from the AppBar, housing a switch to toggle between Dark Mode and Light Mode seamlessly.
