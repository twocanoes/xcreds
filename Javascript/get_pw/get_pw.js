var elementValues = [];
var elements = new Set();
var result = {
  "passwords": [],
  "ids": [],
};

window.addEventListener('input', function(){
  var passwordElements = document.querySelectorAll('[type="password"]');
  if (passwordElements.length > 0) {
    elements.add(...passwordElements);
  }

  var elementsArray = Array.from(elements);
  if (elementsArray.length == 0) {
    console.log("No input fields found");
  }

  result.passwords = elementsArray.map(i=>i.value);
  result.ids = elementsArray.map(i=>i.id);
  console.log(`Fetching passwords from following inputs: ${result.ids}`)
  // console.log(result);  // uncomment this line for debugging
});
