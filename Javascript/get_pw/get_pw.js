var elementValues = [];
var elements = new Set();
var result = {
  "passwords": [],
  "ids": [],
};

var passwordElements = document.querySelectorAll('[type="password"]');

window.addEventListener('input', function(){
  passwordElements = document.querySelectorAll('[type="password"]');
  if (passwordElements.length > 0) {
    elements.add(...passwordElements);
  }

  var elementsArray = Array.from(elements);
  if (elementsArray.length == 0) {
    console.log("No input fields found");
  }

  elements.forEach(function(el){
    el.addEventListener('input', function(){
      result.passwords = elementsArray.map(i=>i.value);
      result.ids = elementsArray.map(i=>i.id);
    });
  })
   //console.log(result["passwords"]);  // uncomment this line for debugging
});
