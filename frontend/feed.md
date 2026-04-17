# Freebay Feed Page - UI Architecture & Data Flux (Flutter)

This document outlines the user interface components, interactive flows, and underlying data structures for the main feed page of the Freebay application, designed for Flutter.

---

## 1. Top Application Bar (Header)
Implemented as a custom `SliverAppBar` or standard `AppBar` to handle global navigation and quick-access notifications.

* **Logo (Top Left - "Freebay"):** * **Action:** Tapping the logo triggers a `ScrollController.animateTo` (moving to offset 0) and calls the feed's refresh method (e.g., via a `RefreshIndicator`).
* **Bell Icon (Notifications):** * **Action:** Pushes a new route to the notification screen.
    * **System:** Handled by `firebase_messaging` (FCM). Uses a `Badge` widget over the `IconButton` to show unread system or social alerts.
* **Paper Plane / Arrow Icon (Direct Messages):** * **Action:** Pushes the Chat/DM inbox route.
    * **System:** Uses a stream from your backend (e.g., Firestore or WebSockets) to update a red dot/counter badge if the user has pending messages.
* **Magnifying Glass (Search):** * **Action:** Opens a `SearchDelegate` or a custom search page overlay. 
    * **System:** Allows searching for posts, products, or users.

---

## 2. Post Creation Prompt (Quick Add)
A persistent widget typically placed at the top of a `CustomScrollView` (inside a `SliverToBoxAdapter`) or as a fixed header above a `ListView`.

* **User Avatar:** Uses a `CircleAvatar` with a `NetworkImage` of the authenticated user.
* **Text Prompt ("No que você está pensando ou vendendo?"):** A styled `Container` wrapped in an `InkWell` or `GestureDetector` that mimics a text field. Tapping it opens the full post-creation modal.
* **Plus (+) Button:** * **Action:** Opens a full-screen `Dialog` or bottom sheet where users can attach media, set prices, and write descriptions.

---

## 3. Feed & Post Component Structure
The feed is a vertical scrolling list, optimally built using `ListView.builder` or `SliverList` for efficient memory management of `Post` objects.

### Post Data Model & UI Mapping
* **Header Profile:**
    * `Profile Picture`: `CircleAvatar`.
    * `Username`: `Text` widget displaying the author.
    * `Role/Tag`: Optional subtitle (e.g., "Vendedor").
* **Media / Product Details (Optional):**
    * `IMG?` (Nullable): Handled via `Image.network` with a placeholder (e.g., `CachedNetworkImage` package) or decoded from base64 if sent directly.
    * `Value?` (Nullable): If present, displays the formatted price (e.g., `R$ 499,90`). If null, it renders as a standard text post.
* **Interaction Bar (Bottom of Post):**
    * **Heart (Like):** Wraps an `Icon` in an `IconButton`. Uses optimistic state updates locally via your state manager (Provider/Riverpod/Bloc) while dispatching an async call to the backend.
    * **Speech Bubble (Comment):** Tapping routes to the detailed post view and requests `FocusNode` to open the keyboard.
    * **Paper Plane (Share):** Triggers the `share_plus` package plugin to invoke native iOS/Android sharing.
    * **Bookmark (Save):** Toggles a boolean to save the listing to local/remote favorites.
* **Body Content:**
    * `Description`: Main text payload.
* **Metrics Footer:** Summarized engagement strings (e.g., "25 Curtidas", "Ver 8 comentários").

### Post Interaction Flux (Detailed View)
* **On Click:** Tapping the post navigates via `Navigator.push` to a `PostDetailScreen(postId: id)`.
* **Threaded Comments:** Comments are fetched and mapped into a recursive **tree structure**. Flutter's `ListView` can be combined with recursive widgets to allow users to reply directly to child comments, collapsing or expanding sub-trees.


---

## 4. Bottom Navigation Bar
Built using Flutter's `BottomNavigationBar` or a custom `Container` aligned to the `bottomNavigationBar` slot of the `Scaffold`.

* **Home (House Icon):** * **State:** Active index (indicated by the primary purple color). 
* **Search (Magnifying Glass):** * **Action:** Switches the index to the Discovery/Search tab.
* **Center Action Button (+ / Wallet):** * **Action:** Opens the User Wallet interface. Can be implemented as a specialized navigation item or a floating button intersecting the nav bar. Allows the user to view balances, manage funds, and view transaction history.
* **Heart Icon (Activity/Favorites):** * **Action:** Switches to the saved items/activity index.
* **Profile (User Icon):** * **Action:** Switches to the user's personal profile and store dashboard.

---

## 5. Theming & Preferences (Light / Dark Mode)
Since this is a Flutter app, theming is handled via the `MaterialApp` widget utilizing `ThemeData` and the `shared_preferences` package for local persistence.

* **State Persistence:** The user's chosen theme (Light, Dark, or System Default) is saved locally on the device using `shared_preferences`.
* **Initialization Flux:**
    1. **App Initialization:** In `main.dart`, before `runApp()`, initialize `SharedPreferences`.
    2. **Read Preference:** Retrieve the stored theme string (e.g., `'light'`, `'dark'`, or null).
    3. **Apply ThemeMode:** Feed this preference into your state manager to control the `themeMode` property of `MaterialApp`.
        * If `'light'`, set to `ThemeMode.light`.
        * If `'dark'`, set to `ThemeMode.dark`.
        * If null (no preference), set to `ThemeMode.system`.
    4. **System Fallback:** When set to `ThemeMode.system`, Flutter automatically respects the native OS theme settings via `MediaQuery.of(context).platformBrightness`.
* **User Toggle:** When the user manually toggles the theme in their settings, update the state manager (which dynamically rebuilds the `MaterialApp` with the new `ThemeMode`) and asynchronously save the new value to `shared_preferences`.