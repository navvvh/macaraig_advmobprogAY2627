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