function createWARCHeader(type, UTC, length, ...args){
    const CRLF = '\r\n';
    ISO = UTC.toISOString().split('.')
    let wHeader = `WARC/1.0${CRLF}`;
    wHeader += `WARC-Type: ${type}${CRLF}`;
    if(type!="warcinfo") {
        wHeader += `WARC-Target-URI: ${args}${CRLF}`
    }else{
        wHeader += `Content-Type: application/warc-fields${CRLF}`
        wHeader += `WARC-Filename: sample.warc${CRLF}`;
    };
    wHeader += `WARC-Date: ${ISO[0]}Z${CRLF}`;
    //${args}${UTC.getFullYear()}${UTC.getMonth()+1}${UTC.getDate()}
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
    warcResponse += `Content-Length: ${text.length}${CRLF}${CRLF}`;
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

function blobToBase64(blob) {
    https://stackoverflow.com/questions/18650168/convert-blob-to-base64
    return new Promise((resolve, _) => {
        const reader = new FileReader()
        reader.onload = () => {
            resolve(reader.result);
        }
        reader.readAsDataURL(blob);
    });
};

async function createWARC(message){
    let UTC = new Date();
    let pageRes, pageBlob, imgBlob, cssBlob;
    let imgReq, imgRes
    let styleReq, styleRes
    let oldHtml, html;
    let warc, oldWARC, oldHeadSize, oldResSize;

    warc = createWARCHeader('warcinfo', UTC, (new TextEncoder().encode(createWARCInfo())).length,);
    warc += createWARCInfo();

    let pageReq = new Request(message.pageURI);
    await fetch(pageReq)
    .then(response =>{
        pageRes = response;
        return pageRes.blob()
    })
    .then(blob => {
        pageBlob = blob;
        return blob.text()
    })
    .then(text => {
        html = text;
        warc += createWARCHeader('request', UTC, (new TextEncoder().encode(createRequest(pageReq))).length, message.pageURI);
        warc += createRequest(pageReq);
        oldWARC = createWARCHeader('response', UTC, (new TextEncoder().encode(createResponse(pageRes))).length + (new TextEncoder().encode(createResponseBlobData(pageBlob,text))).length, message.pageURI);
        oldWARC += createResponse(pageRes);
        oldWARC += createResponseBlobData(pageBlob, html); 
        warc += oldWARC;

        oldHeadSize = new TextEncoder().encode(createResponse(pageRes)).length + new TextEncoder().encode(createResponseBlobData(pageBlob, text)).length -2;
        oldBlobSize = (html.length);
    })

    for(let i=0; i < message.imageURIs.length; i++){
        //nullCheck
        if(message.imageURIs){
            imgReq = new Request(message.imageURIs);
            await fetch(imgReq)
            .then(response =>{
                imgRes = response;
                return imgRes.blob()
            })
            .then(blob => {
                imgBlob = blob;
                if(blob.type == ("image/jpeg" || "image/png" || "image/gif")){
                    return blobToBase64(blob);
                }
                else{
                    return imgBlob.text();
            }
            })
            .then(text => {
                if(imgBlob.type == ("image/jpeg" || "image/png" || "image/gif")){
                    let uri = message.imageURIs[i];
                    let splitUri = "/" + uri.split(new RegExp(message.pageURI))[1];
                    oldHtml = html;
                    let oldHeadSize_re = new RegExp(oldHeadSize);
                    let oldBlobSize_re = new RegExp(oldBlobSize);

                    html = html.replace(new RegExp(splitUri),text);
                    warc = warc.replace(new RegExp(splitUri),text);
                    warc = warc.replace(oldHeadSize_re, (new TextEncoder().encode(createResponse(pageRes)).length + (new TextEncoder().encode(createResponseBlobData(pageBlob, html))).length));
                    warc = warc.replace(oldBlobSize_re, html.length); 

                    console.log("oldHeadSize=", oldHeadSize);
                    console.log("newHeadSize=",new TextEncoder().encode(createResponse(pageRes)).length + (new TextEncoder().encode(createResponseBlobData(pageBlob, html))).length);
                    console.log("oldBlobSize=", oldBlobSize);
                    console.log("newBlobSize=",html.length);

                    oldHeadSize = (new TextEncoder().encode(createResponse(pageRes)).length + (new TextEncoder().encode(createResponseBlobData(pageBlob, html))).length);
                    oldBlobSize = (new TextEncoder().encode(createResponseBlobData(pageBlob, html)).length);
                }
                else{
                    warc += createWARCHeader('request', UTC, createRequest(imgReq).length, message.imageURIs);
                    warc += createRequest(imgReq);
                    warc += createWARCHeader('response', UTC, (new TextEncoder().encode(createResponse(imgRes))).length + (new TextEncoder().encode(createResponseBlobData(imgRes,text))).length, message.imageURIs);
                    warc += createResponse(imgRes);
                    warc += createResponseBlobData(imgBlob,text);
                }
            })
        }
    }

    for(let i=0; i < message.styleURIs.length; i++){
        //nullCheck
        if(message.styleURIs[i]){
            styleReq = new Request(message.styleURIs[i]);
            await fetch(message.styleURIs[i])
            .then(response =>{
                styleRes = response;
                return styleRes.blob()
            })
            .then(blob => {
                styleBlob = blob;
                return blob.text();
            })
            .then(text => {
                warc += createWARCHeader('request', UTC, createRequest(styleReq).length, message.styleURIs);
                warc += createRequest(styleReq);
                warc += createWARCHeader('response', UTC, (new TextEncoder().encode(createResponse(styleRes))).length + (new TextEncoder().encode(createResponseBlobData(styleBlob, text))).length, message.styleURIs);
                warc += createResponse(styleRes);
                warc += createResponseBlobData(styleBlob, text);
            })
        }   
    }
    return warc;
}

chrome.runtime.onMessage.addListener(function(message, sender, sendResponse){
    createWARC(message)
    .then(res => {
            sendResponse(res);
        })
    return true;
})