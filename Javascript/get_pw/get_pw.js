var elements = new Set();
var result = {
  "passwords": [],
  "ids": [],
};

function watchWindow(){
  var passwordElements = document.querySelectorAll('[type="password"]');
  passwordElements.forEach(i=>elements.add(i));
  var elementsArray = Array.from(elements);

  if (elementsArray.length == 0) {
    console.log("No password fields found");
  }

  result.passwords = elementsArray.map(i=>i.value)
    .filter(i=>i !== "");
  result.ids = elementsArray.map(i=>i.id);
  result.ids = [...new Set(result.ids)];
  console.log(result);
}

watchWindow();
window.addEventListener('click', watchWindow);
window.addEventListener('input', watchWindow);
