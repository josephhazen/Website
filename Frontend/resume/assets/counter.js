/*
We want this code to make an http GET request to our API gateway using the invocation link.
*/
const counter = document.getElementById('api-content');
async function visitorCounter() {
    let response = await fetch('https://spit6s7fd7.execute-api.us-east-1.amazonaws.com/apiv1/resume.html');
    let data = await response.json();
    counter.innerHTML = `Number of Visitors: ${data}`;
}

visitorCounter();

