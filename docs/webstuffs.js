function update_current_header ()
{
    var headerNodes = document.body.querySelectorAll("article > h1");
    var asideList = document.body.querySelector("#aside-wrapper > aside > ul");

    var i;
    var currentHeader = null;
    var scrollPos = document.scrollingElement.scrollTop;

    for (i=0; i<headerNodes.length; i++)
    {
        var off = headerNodes[i].offsetTop;
        if (off > scrollPos)
        {
            break;
        }
        else
        {
            currentHeader = i;
        }
    }

    // update all navbar nodes
    currentHeader = Math.min(Math.max(currentHeader, 0), headerNodes.length - 1);
    asideList.childNodes.forEach(function(node)
    {
        node.className = "";
    });

    asideList.childNodes[currentHeader].className = "current drop-shadow-soft";
}

function page_init ()
{
    var headers = new Array();

    var asideNodes = document.body.querySelector("#aside-wrapper > aside");
    var asideList = document.body.querySelector("#aside-wrapper > aside > ul");
    var tocNodes = document.body.querySelector("#toc-wrapper > aside");
    var tocList = document.body.querySelector("#toc-wrapper > aside > ul");
    var headerNodes = document.body.querySelectorAll("article > h1");
    
    // Clear & Initialize ToC and GOTO list
    while (asideList.firstChild)
    {
        asideList.removeChild(asideList.firstChild);
    }

    while (tocList.firstChild)
    {
        tocList.removeChild(tocList.firstChild);
    }
    
    // Grab a bunch of headers from the page's article sections
    headerNodes.forEach(currentNode =>
    {
        // console.log(currentNode.textContent + " [" + currentNode.getAttribute("id") + "]");

        // and append it into the ToC and GOTO side navbar
        var listNode = document.createElement("li");
        var linkNode = document.createElement("a");

        // set link attributes
        linkNode.setAttribute("href", "#" + currentNode.getAttribute("id"));
        linkNode.textContent = currentNode.textContent;

        // and append it to node(s)
        listNode.appendChild(linkNode);
        asideList.appendChild(listNode.cloneNode(true));
        tocList.appendChild(listNode.cloneNode(true));
    });

    // Update current header / section index
    update_current_header();
    document.body.onscroll = update_current_header;
}