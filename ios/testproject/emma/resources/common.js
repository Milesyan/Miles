
function logInfo(info) { linkHelper("info://"+info); }

function linkHelper(link) {
    
    var iframe = document.createElement("IFRAME");
    
    iframe.setAttribute("src", link);
    
    document.documentElement.appendChild(iframe);
    
    iframe.parentNode.removeChild(iframe);
    
    iframe = null;
    
}

function sizeChanged()
{
    linkHelper("sizechanged://" + document.getElementById('content').offsetHeight);
}

function domReady() { linkHelper("domready://"); }