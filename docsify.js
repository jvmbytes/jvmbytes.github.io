function dom(id) {
  return document.getElementById(id)
}

function ndom(n) {
  return document.createElement(n)
}

function tagdom(n) {
  return document.getElementsByTagName(n)[0]
}

function GenPageId() {
  var gid = document.location.href;
  gid = gid.replace("http://", "");
  gid = gid.replace("https://", "");
  gid = gid.replace(doc_domain, "");
  gid = gid.replace(".html", "");
  gid = gid.replace(".md", "");
  gid = gid.replace(".markdown", "");

  if (gid.startsWith("?")) {
    let index = gid.indexOf("#");
    if (index > 0) {
      gid = git.substr(index);
    }
  }
  if (gid.startsWith("/")) {
    gid = gid.substr(1);
  }
  if (gid.startsWith("#")) {
    gid = gid.substr(1);
  }
  if (gid.startsWith("/")) {
    gid = gid.substr(1);
  }
  if (gid[gid.length - 1] == '/') {
    gid = gid.substr(0, gid.length - 1);
  }
  var len = gid.lastIndexOf("/");
  if (gid.length - len > 25) {
    gid = gid.substr(len + 1);
  } else {
    len = gid.lastIndexOf("/", len - 1);
    if (gid.length - len > 25) {
      gid = gid.substr(len + 1);
    }
  }
  if (gid.length > 50) {
    gid = gid.substr(gid.length - 50);
  }
  return gid;
}

function NewGitalk() {
  return new Gitalk({
    accessToken: gitalk_access_token,
    clientID: gitalk_client_id,
    clientSecret: gitalk_client_secret,
    repo: gitalk_repo,
    owner: gitalk_user,
    admin: [gitalk_user],
    id: GenPageId(),
    language: 'zh-CN',
    distractionFreeMode: true
  });
}

const gitalk = NewGitalk(); // docsify gitalk plugin init needed

function reset_gitalk_container() {
  var c = dom("gitalk-container")
  if (c) {
    c.innerHTML = ""
  } else {
    c = ndom("div")
    c.setAttribute("id", "gitalk-container")
    tagdom("article").appendChild(c)
  }
  return c
}

var gitalk_reload_timer;

function gitalk_loader() {
  if (gitalk_reload_timer) {
    clearTimeout(
      gitalk_reload_timer)
  }
  reset_gitalk_container()
  gitalk_reload_timer = setTimeout(
    function() {
      NewGitalk().render("gitalk-container");
    }, 5 * 1000);
}

window.$docsify = {
  name: doc_title,
  repo: '',
  themeColor: '#19BE6B',
  loadSidebar: false,
  subMaxLevel: 4,
  loadNavbar: true,
  notFoundPage: true,
  search: 'auto',
  basePath: doc_base_url,
  plugins: [
    function(hook, vm) {
      hook.doneEach(gitalk_loader);
    }
  ]
}
