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
