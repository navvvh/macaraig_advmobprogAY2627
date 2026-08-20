# Vhan Hajj A. Macaraig
## INF231MWA
## CTADMOBL Advance Mobile Programming


A new Flutter project focuses on adnvance topics. Covering the Mobile to Web Transaction

## Lab Activity Instance

Lab Activity 2: Discussion

The application uses a layered architecture where the Model, Service, and Screen work together. The Model represents the API data, the Service fetches data from the API and converts it into model objects, and the Screen displays the data using FutureBuilder. When a product is selected, the app navigates to the product details screen.

This activity introduces a cleaner design pattern by separating the application into Models, Services, Screens, Widgets, and Providers. This improves code organization, readability, reusability, and makes the application easier to maintain and expand.

--------------------------------------------------------------------------------------------

Lab Activity 3: Discussion

The application uses a layered architecture where the Cart Model, Cart Service, and Cart Screen work together. The Cart Model holds the cart data, the Cart Service gets the data from the API, and the Cart Screen displays the products. When I click a product in the cart, the app gets its product ID and uses it to open the same Product Details Screen.

This activity also improves the design pattern by separating the Models, Services, Screens, Widgets, and Providers. This makes the code easier to understand and organize. We also used Get by ID in the Cart API to get the cart of a specific user instead of getting all the carts.