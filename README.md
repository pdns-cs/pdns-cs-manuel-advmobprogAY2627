# PRINCESS DENESE M. MANUEL
## INF231MWA
## CTADMOBL Advance Mobile Programming

A Flutter project that focuses on advance topics covering the Mobile to Web Transactions.

## Lab Activity 2: discussion

**How the model, service, and screen interact to render the API endpoint:**

1. **Model** (`product.dart`) — Defines the shape of the data (`Product`, `ProductDimensions`, `ProductReview`, `ProductMeta`) and has a `fromJson()` factory that converts raw JSON into Dart objects.
2. **Service** (`product_service.dart`) — Calls the API (`http.get`) using the `host` from `constants.dart`, decodes the JSON response, and maps each item through `Product.fromJson()` to return a `List<Product>`.
3. **Screen** (`product_screen.dart`) — Calls `ProductService().getAllProducts()` inside `initState()`, stores it as a `Future`, and passes it to a `FutureBuilder`. The `FutureBuilder` shows a loader while waiting, an error message if it fails, and the `GridView` of product cards once data arrives.

In short: **Model = data structure → Service = fetch and convert → Screen = display and react to state (loading/error/success).** Each layer only knows about the one below it, so the UI never talks to the API directly.

**New design pattern in this activity:**

This activity introduces a **layered/separation-of-concerns architecture** (similar to MVVM), organizing the app into `models/`, `services/`, `providers/`, `screens/`, and `widgets/` folders instead of putting everything in one file. It also introduces the **Provider pattern** via `ThemeProvider` (a `ChangeNotifier`), which lets any widget listen to and update shared state (dark/light mode) without passing data manually through constructors — this is the app's basic state management solution.

## Lab Activity 3: discussion

The cart feature follows the same model-service-screen pattern. `cart.dart` defines the `Cart` and `CartProduct` objects based on the DummyJSON cart response. `cart_service.dart` handles the API calls, converts JSON into cart models, and keeps the networking code outside of the UI. `cart_screen.dart` calls the service with a `FutureBuilder`, then renders the cart products, totals, loading state, and error state.

The updated design pattern now has matching product and cart layers: models describe API data, services fetch and parse the API response, and screens display the result. This makes the app easier to extend because a screen can use a service without manually decoding JSON inside the widget.

For the Cart endpoint, `getSeededCartByUserId()` shows how `/carts/user/{userId}` fetches only one user's seeded DummyJSON cart. DummyJSON's `/carts/add` endpoint only simulates adding a cart and does not permanently save it, so the visible cart uses `getCartByUserId()` to render only products added during the current app session. When an item is tapped, the app uses the product id with `/products/{id}` through `ProductService.getProductById()` and sends the complete `Product` object to the existing `ProductDetailScreen`.
