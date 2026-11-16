$f = "app\android\app\src\main\AndroidManifest.xml"
$t = Get-Content $f -Raw
if ($t -notmatch 'android.permission.INTERNET') {
  $t = $t -replace '<application', '<uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <application'
  Set-Content $f $t
}
