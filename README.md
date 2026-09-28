# Vhan Hajj A. Macaraig
## INF231MWA
## CTADMOBL Advance Mobile Programming


A new Flutter project focuses on adnvance topics. Covering the Mobile to Web Transaction

## Lab Activity Instance
Lab Activity 1: Discussion

setState only works on one screen leave it, and the value resets. Provider shares state across the whole app, so one change updates everywhere. We used setState
for the counter and Provider for the theme.

--------------------------------------------------------------------------------------------

Lab Activity 2: Discussion

The application uses a layered architecture where the Model, Service, and Screen work together. The Model represents the API data, the Service fetches data from the API and converts it into model objects, and the Screen displays the data using FutureBuilder. When a product is selected, the app navigates to the product details screen.

This activity introduces a cleaner design pattern by separating the application into Models, Services, Screens, Widgets, and Providers. This improves code organization, readability, reusability, and makes the application easier to maintain and expand.

--------------------------------------------------------------------------------------------

Lab Activity 3: Discussion

The application uses a layered architecture where the Cart Model, Cart Service, and Cart Screen work together. The Cart Model holds the cart data, the Cart Service gets the data from the API, and the Cart Screen displays the products. When I click a product in the cart, the app gets its product ID and uses it to open the same Product Details Screen.

This activity also improves the design pattern by separating the Models, Services, Screens, Widgets, and Providers. This makes the code easier to understand and organize. We also used Get by ID in the Cart API to get the cart of a specific user instead of getting all the carts.

---------------------------------------------------------------------------------------------

Lab Activity 4: Discussion

When a user logs in, UserService sends their username and password to the DummyJSON login API. If it's correct, the returned user info gets saved on the device using SharedPreferences, so the app remembers the user even after it's closed. The Splash screen checks this saved data first — if someone's already logged in, it goes straight to Home; if not, it goes to Sign In. After a fresh login, that same user data is passed along to Home so the Profile screen can display it (name, email, gender, user ID) and 
log the user out when needed.

This follows the same pattern used for Cart in the earlier activity: the User model just holds the data, UserService handles the login and saving/loading, and the screens just display things and call UserService when they need data — they don't deal with storage directly.

For the cart, instead of always showing one fixed user's cart, the app now gets the ID of whoever is actually logged in and uses that to fetch their specific cart from the API. So the cart shown always matches the signed-in user.

---------------------------------------------------------------------------------------------

## Lab Activity 5: Discussion

The sign-in screen supports two distinct flows so the previous API activity can still be compared with Firebase. DummyJSON sign-in sends a username and password to `https://dummyjson.com/auth/login`, saves the returned sample profile and tokens, and refreshes its access token when the app restores that session. For example, DummyJSON documents `emilys` / `emilyspass` as sample credentials. DummyJSON is a practice API; its token and account are separate from Firebase.

Firebase sign-in uses email and password through the Firebase Authentication SDK. The Firebase signup screen collects first name, last name, age, contact number, username, email, and a validated password. Firebase manages the authenticated session and its ID-token refresh. The app stores profile details locally for display; it does not store the password. Firebase password changes and account deletion require reauthentication. Username edits update Firebase's display name; DummyJSON username edits update only the local sample profile.

`UserService` keeps both authentication flows and local profile storage out of the screens. The splash screen restores the correct session type, while logout clears the local session and signs out Firebase. Firebase Authentication is configured in this activity; the app does not use Firebase Realtime Database or Cloud Firestore, so database security rules are not part of this implementation. DummyJSON password changes and account deletion are not available through this app because it is only used here as a sample login API.
