# ============================================================
# Campus portal auto-login - CONFIG (example template)
#
# Copy this file to "config.ps1" and edit it.
# config.ps1 is ignored by git (.gitignore) - NEVER commit it,
# because it holds your real password in plaintext.
# ============================================================

$cfg = @{
    # ---------------- account ----------------
    User = "YOUR_CAMPUS_ID"      # campus account: student id / staff id / phone
    Pass = "YOUR_PASSWORD"       # auth password (plaintext - keep this file private)

    # ---------------- portal (capture with F12, see README) ----------------
    # Case A - POST form (default, current BUPT style):
    #   POST <Portal><LoginPath>  with form fields in LoginFields
    Portal    = "http://10.3.8.211"   # captive portal base URL
    LoginPath = "/login"              # value of the <form action="...">
    LoginFields = @{ user = "{user}"; pass = "{pass}" }   # field name -> {user}/{pass} markers
    LoginMethod = "POST"              # POST | GET

    # Case B - GET style (older Dr.COM), uncomment and set LoginMethod = "GET":
    # LoginUrl = "http://10.3.8.211/drcom/login?callback=dr1003&DDDDD={user}&upass={pass}&R1=0&R2=&R3=0&R6=0&para=00&0MKKey=123456"

    # Fragment of the login page that appears on failure (re-rendered form).
    # Leave "" to skip this check. Must be a regex-safe literal.
    LoginFailMarker = 'action="login"'

    # ---------------- online check ----------------
    # A page that is only reachable while authenticated. Needle = marker text
    # found in that page. HTTPS sites are best (portals cannot fake them).
    CheckUrl    = "https://www.baidu.com"
    CheckNeedle = "baidu.com"

    # ---------------- wifi filter (event mode) ----------------
    # Only act while connected to one of these SSIDs. Empty list = no filter.
    # Add more, e.g. @("BUPT-portal","BUPT-WiFi"); for campus wired use @().
    OnlineSSIDs = @("BUPT-portal")
}
