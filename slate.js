//Create the operations needed
var fullScreen = slate.operation("move", {
    "x" : "screenOriginX",
    "y" : "screenOriginY",
    "width" : "screenSizeX",
    "height" : "screenSizeY"
});
var halfRight = slate.operation("push", {
    "direction" : "right",
    "style" : "bar-resize:screenSizeX/2"
});
var lessRight = slate.operation("push", {
    "direction" : "right",
    "style" : "bar-resize:screenSizeX/3"
});
var mostRight = slate.operation("push", {
    "direction" : "right",
    "style" : "bar-resize:2*screenSizeX/3"
});
var halfLeft = slate.operation("push", {
    "direction" : "left",
    "style" : "bar-resize:screenSizeX/2"
});
var lessLeft = slate.operation("push", {
    "direction" : "left",
    "style" : "bar-resize:screenSizeX/3"
});
var mostLeft = slate.operation("push", {
    "direction" : "left",
    "style" : "bar-resize:2*screenSizeX/3"
});
var halfDown = slate.operation("move", {
    "x": "windowTopLeftX",
    "y": "windowTopLeftY",
    "width": "windowSizeX",
    "height": "screenSizeY/2"
});
var pushDown = slate.operation("push", {
    "direction" : "down"
});
var halfUp = slate.operation("move", {
    "x": "windowTopLeftX",
    "y": 0,
    "width": "windowSizeX",
    "height": "screenSizeY/2"
});
var pushUp = slate.operation("push", {
    "direction" : "up"
});

//Focus operations
var terminalFocus = slate.operation("focus", {
    "app" : "iTerm"
});
var editorFocus = slate.operation("focus", {
    "app" : "Sublime Text 2"
});
var browserFocus = slate.operation("focus", {
    "app": "Google Chrome"
});

//Helper functions
var isOnRight = function(win){
    winRect = win.rect();
    winPos = winRect.x + winRect.width/2;
    screenRect = slate.screen().rect();
    if(winPos > screenRect.x + screenRect.width/2){
        return true;
    }
    return false;
};
var isOnLeft = function(win){
    winRect = win.rect();
    screenRect = slate.screen().rect();
    winPos = winRect.x + winRect.width/2;
    if(winPos < screenRect.x + screenRect.width/2){
        return true;
    }
    return false;
};


//Bind the operations
slate.bind("space:ctrl,alt", function(win){
    win.doOperation(fullScreen);
    return;
});
slate.bind("left:ctrl,alt", function(win){
    win.doOperation(halfLeft);
    return;
});
slate.bind("right:ctrl,alt", function(win){
    win.doOperation(halfRight);
    return;
});
slate.bind("up:ctrl,alt", function(win){
    win.doOperation(halfUp);
    win.doOperation(pushUp);
    return;
});
slate.bind("down:ctrl,alt", function(win){
    win.doOperation(halfDown);
    win.doOperation(pushDown);
    return;
});

slate.bind("right:ctrl,alt,cmd", function(win){
    if(isOnLeft(win)){
        win.doOperation(mostLeft);
    }
    else if(isOnRight(win)){
        win.doOperation(lessRight);
    }
    else{
        win.doOperation(lessRight);
    }
    return;
});

slate.bind("left:ctrl,alt,cmd", function(win){
    if(isOnLeft(win)){
        win.doOperation(lessLeft);
    }
    else if(isOnRight(win)){
        win.doOperation(mostRight);
    }
    else{
        win.doOperation(lessLeft);
    }
    slate.log(slate.app().name());
    return;
});

slate.bind("left:ctrl", function(win){
    var id = win.screen().id();
    var move = slate.operation("throw", {
        "screen":(id-1).toString()
    });
    win.doOperation(move);
});
slate.bind("right:ctrl", function(win){
    var id = win.screen().id();
    var move = slate.operation("throw", {
        "screen":(id+1).toString()
    });
    win.doOperation(move);
});
slate.bind("5:ctrl,alt,cmd,shift", terminalFocus);
slate.bind("6:ctrl,alt,cmd,shift", editorFocus);
slate.bind("4:ctrl,alt,cmd,shift", browserFocus);

