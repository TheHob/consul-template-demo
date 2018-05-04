<!DOCTYPE html>
<html>
<head>
<div id="header">
   <img src="images/hashicorp.png" alt="logo" />
</div>
</head>
<style>
body {
    font: bold 28px Verdana, Arial, sans-serif;
    background-color: #FFFFFF;
    background-image: url("images/consul.jpg");

}
h3 {
    font: normal 18px Verdana, Arial, sans-serif;
}
h4 {
    font: bold 12px Verdana, Arial, sans-serif;
}
</style>

<body>
Your web servers are: <br />
<h3>
{{range service "web@dc1"}}
Name: {{.Node}} <br /> IP address: {{.Address}} <br /> Listening on: {{.Port}} <br /> <br /> {{end}}
</h3>
<h4>
Current host: HOSTNAME
</h4>
</body>
<div class="siteFooterBar">
    <div class="content">
        <img src="images/terraform.jpg">
            <div class="foot"></div>
    </div>
</div>
</html>
