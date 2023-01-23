function getImageURIs(URIs){
    const imageURIs = [];
    for(i=0;i<URIs.length;i++){
    imageURIs.push(URIs[i].src);
    }
    return imageURIs;
};
function getStyleURIs(URIs){
    const styleURIs = [];
    for(i=0;i<URIs.length;i++){
    styleURIs.push(URIs[i].href);
    }
    return styleURIs;
};
function download_WARC(data){
    console.log(data);
    let now = new Date();
    let GMT = now.toGMTString();

    const blob = new Blob([data], {type: 'text/plain'});

    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    document.body.appendChild(a);
    a.download = `${document.URL}.warc`;
    a.href = url;
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
    console.log("archive finish");
}

function sendTextData(URIs, sendMessage){
    chrome.runtime.sendMessage(URIs, sendMessage);
};

//if(document.domain == "hope.fun.ac.jp"){
    window.addEventListener('load', (event) => {
        let URIs = {pageURI: document.URL};
        URIs.imageURIs = getImageURIs(document.images);
        URIs.styleURIs = getStyleURIs(document.styleSheets);
        console.log(URIs);
        sendTextData(URIs, download_WARC);
    });
//};
