var elements = new Set();
var result = {
  "passwords": [],
  "ids": [],
};

// Collect initial password elements
var passwordElements = document.querySelectorAll('[type="password"]');

window.addEventListener('input', function(event){
  var triggeredElement = event.target;
  
  // Check if element is in the initial password elements array
  var isPasswordField = Array.from(passwordElements).includes(triggeredElement);
  
  if (isPasswordField) {
    elements.add(triggeredElement);
    
    result.passwords = Array.from(elements).map(i => i.value);
    result.ids = Array.from(elements).map(i => i.id);
    
    //console.log(result.passwords);
  }
});
