const contact = document.getElementById('contact');
async function contactForm() {
    let response = await fetch('https://spit6s7fd7.execute-api.us-east-1.amazonaws.com/apiv1/resume.html');
    let data = await response.json();
    counter.innerHTML = `Number of Visitors: ${data}`;
}

contactForm();