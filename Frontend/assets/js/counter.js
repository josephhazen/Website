/*
We want this code to make an http GET request to our API gateway using the invocation link.
*/
const counter = document.querySelector(".counter-number");
async function viewCounter() {
    let response = await fetch('https://spit6s7fd7.execute-api.us-east-1.amazonaws.com/apiv1/resume.html');
    let data = await response.json();
    counter.innerHTML = `${data}`;
    console.log(data)

viewCounter();
}