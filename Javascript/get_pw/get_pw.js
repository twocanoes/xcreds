var elements = new Set();
var result = {
  "passwords": [],
  "ids": [],
};

// Collect password fields, descending into shadow roots.
//
// document.querySelectorAll() does not traverse shadow DOM, so IdPs that render
// their login form with web components hide the password field from the query.
// authentik is one such IdP: the field is <input id="ak-stage-password-input">
// inside the shadow root of <ak-stage-password>, and capture silently returns
// nothing, so the local account password can never be set.
function collectPasswordFields(root) {
  root.querySelectorAll('[type="password"]').forEach(i => elements.add(i));
  root.querySelectorAll('*').forEach(function (e) {
    if (e.shadowRoot) {
      collectPasswordFields(e.shadowRoot);
    }
  });
}

function watchWindow(){
  collectPasswordFields(document);
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
