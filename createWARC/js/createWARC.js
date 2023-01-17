function createWARCHeader(type, UTC, length, ...args){
    const CRLF = '\r\n';
    ISO = UTC.toISOString().split('.')
    let wHeader = `WARC/1.0${CRLF}`;
    wHeader += `WARC-Type: ${type}${CRLF}`;
    if(type!="warcinfo") {
        wHeader += `WARC-Target-URI: ${args}${CRLF}`
    }else{
        wHeader += `Content-Type: application/warc-fields${CRLF}`
    };
    wHeader += `WARC-Date: ${ISO[0]}Z${CRLF}`;
    wHeader += `WARC-Filename: ${args}${UTC.getFullYear()}${UTC.getMonth()+1}${UTC.getDate()}.warc${CRLF}`;
    wHeader += `WARC-Record-ID: <urn:uuid:${generateUUID()}>${CRLF}`;
    wHeader += `Content-Length: ${length-2}${CRLF}${CRLF}`;
    return wHeader;
};
function  createWARCInfo(){
    const CRLF = '\r\n';
    const LF = '\n'
    let wInfo = `software: getPageData${CRLF}`;
    wInfo += `format: WARC File Format 1.0${CRLF}`;
    wInfo += `conformsTo: http://bibnum.bnf.fr/WARC/WARC_ISO_28500_version1_latestdraft.pdf${CRLF}`;
    wInfo += `http-header-user-agent: ${navigator.userAgent}${CRLF}${CRLF}${CRLF}${CRLF}`;
    return wInfo;
};
function createRequest(request){
    const CRLF = '\r\n';
    let warcRequest = `Content-Type: application/http;msgtype=request${CRLF}`;
    warcRequest += `${request.method} ${request.url} HTTP/1.1${CRLF}`;
    warcRequest += `User-Agent: ${navigator.userAgent} ${CRLF}`;
    warcRequest += `Connection: close ${CRLF}${CRLF}${CRLF}${CRLF}`;
    return warcRequest;
};
function createResponse(response){
    const CRLF = '\r\n';
    let warcResponse = `HTTP/1.1 ${response.status} ${response.type}${CRLF}`;
    warcResponse += `Content-Type: application/http;msgtype=request${CRLF}`;
    return warcResponse;
};
function createResponseBlobData(blob,text){
    const CRLF = '\r\n';
    const LF = '\n'
    warcResponse = `Content-Type: ${blob.type}${CRLF}`;
    warcResponse += `Content-Length: ${blob.size}${CRLF}${CRLF}`;
    warcResponse += `${text}${CRLF}${CRLF}${CRLF}`;
    return warcResponse;
}
function generateUUID(){
    // https://github.com/GoogleChrome/chrome-platform-analytics/blob/master/src/internal/identifier.js
    let chars = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.split('');
    for (let i = 0, len = chars.length; i < len; i++) {
        switch (chars[i]) {
            case 'x':
                chars[i] = Math.floor(Math.random() * 16).toString(16);
                break;
            case 'y':
                chars[i] = (Math.floor(Math.random() * 4) + 8).toString(16);
                break;
        }
    }
    return chars.join('');
};

function blobToBase64(blob, warc) {
    https://stackoverflow.com/questions/18650168/convert-blob-to-base64
    return new Promise((resolve, _) => {
        const reader = new FileReader();
        reader.onloadend = () => resolve(reader.result.split(',')[1]);
        reader.readAsDataURL(blob);
    });
};

async function createWarc(message){
    let UTC = new Date();
    let pageBuff, pageBlob;
    let imgBuff, imgBlob;
    let cssBuff, cssBlob;

    let warc = createWARCHeader('warcinfo', UTC, (new TextEncoder().encode(createWARCInfo())).length,);
    warc += createWARCInfo();
    const page = new Request(message.pageURI);
    await fetch(page)
    .then(response => {
        pageBuff = response;
        warc += createWARCHeader('request', UTC, (new TextEncoder().encode(createRequest(page))).length, message.pageURI );
        warc += createRequest(page);
        console.log(response);
        return response.blob();
    })
    .then(blob => {
        pageBlob = blob;
        return blob.text()
    })
    .then(text => {
        warc += createWARCHeader('response', UTC, (new TextEncoder().encode(createResponse(pageBuff))).length + (new TextEncoder().encode(createResponseBlobData(pageBlob, text))).length, message.pageURI);
        warc += createResponse(pageBuff);
        warc += createResponseBlobData(pageBlob, text);
    })
    
    for(let i=0; i < message.imageURIs.length; i++){
        //nullCheck
        if(message.imageURIs[i]){
            const img = new Request(message.imageURIs[i]);
            await fetch(img)
            .then(response =>{
                imgBuff = response;
                warc += createWARCHeader('request', UTC, createRequest(img).length, message.imageURIs[i]);
                warc += createRequest(img);
                return response.blob();
            })
            .then(blob => {
                imgBlob = blob;
                return blob.text();
            })
            .then(text =>{
                warc += createResponse(imgBuff);
                blobToBase64(imgBlob)
                .then(base64 =>{
                    warc += createWARCHeader('response', UTC, (new TextEncoder().encode(createResponse(imgBuff))).length + (new TextEncoder().encode(createResponseBlobData(imgBlob, base64))).length, message.imageURIs[i]);
                    warc += createResponseBlobData(imgBlob, base64);
                    return warc;
                })
            })
        }
    }

    for(let i=0; i<message.styleURIs.length; i++){
        //nullCheck
        if(message.styleURIs[i]){
            const css = new Request(message.styleURIs[i]);
            await fetch(css)
            .then(response => {
                cssBuff = response;
                warc += createWARCHeader('request', UTC, createRequest(css).length, message.styleURIs[i]);
                warc += createRequest(css);
                return response.blob()
            })
            .then(blob => {
                cssBlob = blob
                return blob.text();
            })
            .then(text => {
                warc += createWARCHeader('response', UTC, (new TextEncoder().encode(createResponse(cssBuff))).length + (new TextEncoder().encode(createResponseBlobData(cssBlob, text))).length, message.styleURIs[i]);
                warc += createResponse(cssBuff);
                warc += createResponseBlobData(cssBlob, text);
            })
        }
    }
    return warc;
}

chrome.runtime.onMessage.addListener(function(message, sender, sendResponse){
    createWarc(message)
    .then(
        res => {
            // console.log(message);
            sendResponse(res);
        }
    )
    return true;
})