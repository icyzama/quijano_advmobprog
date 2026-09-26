# Lab Activity 2: Architecture & API Discussion

## 1. Interaction Between Model, Service, and Screen
* **Service (`product_service.dart`)**: Issues an HTTP GET request to the remote endpoint hosted on `$host/products` and converts the raw HTTP response string into JSON.
* **Model (`product.dart`)**: Parses raw JSON maps via `Product.fromJson()` factory methods into strongly typed `Product` Dart objects.
* **Screen (`product_screen.dart`)**: Uses a `FutureBuilder` to trigger the service call, process data, and dynamically construct grid views using `CustomText` and image widgets.

## 2. Explanation of Design Pattern
The application uses a **Layered Model-View-Service Architecture** combined with **Provider State Management**:
* **Model Layer**: Encapsulates data contracts.
* **Service Layer**: Isolates external network calls from the UI.
* **Presentation Layer (Screens/Widgets)**: Renders UI components declaratively.
* **State Management (Provider)**: Decouples global state (such as theme switching) from local widget trees.

## Lab Activity 4: Discussion

### User Model, Service, and Screen Interaction
The application now keeps user responsibility separated across layers. DummyJSON API responses are handled by `UserService`, converted into a strongly typed `User` model, persisted through `SharedPreferences`, and then rendered by screens such as `SplashScreen`, `SignInScreen`, `ProfileScreen`, and `CartScreen`. Screens handle user interaction and navigation only; API calls and saved session logic stay inside `UserService`.

### Profile API/Data Flow
Authentication uses the real DummyJSON endpoint at `$host/auth/login`. A successful response provides authenticated user fields such as `id`, `username`, `email`, `firstName`, `lastName`, `gender`, `image`, `accessToken`, and `refreshToken`. `UserService` also attempts to call `$host/auth/me` with the access token so the saved `User` can include additional supported profile fields such as `age`. The profile screen reads the restored `User` from `UserService` and renders only the fields available on the model.

### Persistent Authentication
After login, `UserService.saveUserData()` serializes the authenticated `User` into `SharedPreferences`. On app launch, `SplashScreen` calls `UserService.isLoggedIn()` and restores the saved user session instead of using a hardcoded flag. If a valid saved user and token exist, the app navigates to the home shell; otherwise it clears into the sign-in screen. Logout removes the saved user data and uses route-stack clearing so the back button cannot reopen authenticated pages.

### Updated Design Pattern
The project continues to use a layered Model-View-Service structure with Provider for shared theme state. The `models` directory contains data contracts for products, carts, and users. The `services` directory owns API and persistence logic. The `screens` directory renders full user flows such as product browsing, sign-in, profile, and cart. The `widgets` directory contains reusable presentation widgets such as custom text, logo rendering, information rows, and reusable empty/error states. `providers/theme_provider.dart` remains responsible for global light/dark theme changes.

### Cart by User ID
The cart no longer uses a hardcoded account id. `CartScreen` restores the authenticated user through `UserService.getUser()`, reads `user.id`, and passes that value into `CartService.getCartByUserId(user.id)`, which calls DummyJSON at `$host/carts/user/{userId}`. Product detail add-to-cart follows the same authenticated-user flow before calling `CartService.addToCart()`. If the API returns no cart for the signed-in user, the screen renders a professional empty state instead of failing.
