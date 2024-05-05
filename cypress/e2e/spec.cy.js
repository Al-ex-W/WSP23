describe("Mitt test", () => {
  // Generate a random number to use as part of the username to ensure uniqueness
  let user = Math.floor(Math.random() * 66657676);
  let password = "123"; // Password for the user

  // Test case for user registration process
  it("Fyller i Signup-formulär", () => {
    cy.visit("localhost:4567/"); // Visit the home page
    cy.contains(/\bLog in\b/).click(); // Find and click the 'Log in' button
    cy.url().should("include", "/login"); // Ensure that the URL includes '/login'
    cy.contains(/\bregister\b/).click(); // Find and click the 'register' link or button
    cy.url().should("include", "/register"); // Ensure that the URL includes '/register'
    
    // Fill in the registration form with the generated username and password
    cy.get('[name="username"]').type(`test${user}`); // Enter the username
    cy.get('[name="password"]').type(password); // Enter the password
    cy.get('[name="password_confirm"]').type(password); // Confirm the password
    cy.contains(/\bSign up\b/).click(); // Find and click the 'Sign up' button
  });

  // Test case for user login process
  it("Loggar in", () => {
    cy.visit("localhost:4567/"); // Visit the home page
    cy.contains(/\bLog in\b/).click(); // Find and click the 'Log in' button
    cy.url().should("include", "/login"); // Ensure that the URL includes '/login'
    
    // Login using the credentials used during the registration process
    cy.get('[name="username"]').type(`test${user}`); // Enter the username
    cy.get('[name="password"]').type(password); // Enter the password
    cy.get('[type="submit"]').contains(/\bLog in\b/).click(); // Find the submit button and click it
    cy.contains(user); // Verify that the username is present on the page after login
  });

});
