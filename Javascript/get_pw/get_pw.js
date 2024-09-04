var elementValues = [];
var elements = [];
var result = {
  "passwords": [],
  "ids": [],
};
window.addEventListener('input', function(){
  elements = document.querySelectorAll('[type="password"]');

  for (let i = 0; i < elements.length; i++) {
    elements[i].addEventListener('input', function(){
      result.passwords = Array.from(elements).map(i=>i.value);
      result.ids = Array.from(elements).map(i=>i.id);
    });
  };
});
