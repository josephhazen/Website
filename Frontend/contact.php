<?php
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $name = $_POST["name"];
    $email = $_POST["email"];
    $message = $_POST["message"];
    
    // Send email notification (replace with your email sending code)
    $to = "jhazen@horizontech.cloud";
    $subject = "New Contact Form Submission";
    $body = "Name: $name\nEmail: $email\nMessage: $message";
    mail($to, $subject, $body);

    // Redirect to thank you page
    header("Location: index.html");
    exit;
}
?>
