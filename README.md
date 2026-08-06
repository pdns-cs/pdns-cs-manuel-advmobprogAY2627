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
