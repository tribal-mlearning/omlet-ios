
function addPhoneGapFile(path) {
	var IS_ANDROID = (navigator.appVersion.indexOf('Android') != -1);
	var IS_IOS = (navigator.userAgent.indexOf('iPhone') != -1 || navigator.userAgent.indexOf('iPod') != -1 || navigator.userAgent.indexOf('iPad') != -1);        

	if (IS_ANDROID) {
		document.write('<script src="' + path + 'phonegap-android-1.3.0.js" type="text/javascript" charset="utf-8"></script>')
	} else if (IS_IOS) {
		document.write('<script src="' + path + 'phonegap-ios-1.3.0.js" type="text/javascript" charset="utf-8"></script>')
	}
}
