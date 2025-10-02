const USE_GENDER_PILL = true;           // show Job + Flag + Gender
const FLAG_DIR = "flag";
const FLAG_DEFAULT = "un";
const AVATAR_ICON = "logo/avatar.svg";

const nui = (name, data = {}) =>
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: "POST",
    headers: { "Content-Type": "application/json; charset=UTF-8" },
    body: JSON.stringify(data),
  });

// Build a map from countries.json => { normalizedNameOrAlias: "au" }
let COUNTRY_INDEX = {};
let LAST_CHARACTERS = null;

const normalizeKey = (s) =>
  String(s || "")
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\-]+/g, "_")
    .replace(/^_+|_+$/g, "");

// Load on boot (non-blocking)
fetch("countries.json")
  .then((r) => r.json())
  .then((list) => {
    const idx = {};
    const add = (k, code) => { if (k && code) idx[normalizeKey(k)] = code; };
    list.forEach((x) => {
      const code = String(x.code || x.alpha2 || x.iso2 || x.iso || x.abbr || "").toLowerCase();
      if (!code) return;
      if (x.name) add(x.name, code);
      (Array.isArray(x.aliases)  ? x.aliases  : []).forEach((a) => add(a, code));
      (Array.isArray(x.demonyms) ? x.demonyms : []).forEach((d) => add(d, code));
      add(code, code);
    });
    COUNTRY_INDEX = idx;
  })
  .catch(() => {})
  .finally(() => { if (LAST_CHARACTERS) renderCards(LAST_CHARACTERS); });

// quick extras not covered by countries.json
const EXTRA_DEMONYMS = {
  english: "gb-eng",
  scottish: "gb-sct",
  welsh: "gb-wls",
  british: "gb",
  kiwi: "nz",
  american: "us",
};

const root = document.getElementById("root");
const dock = document.getElementById("dockInner");
const modal = document.getElementById("modal");
const createForm = document.getElementById("createForm");
const cancelCreate = document.getElementById("cancelCreate");
const nationalitySelect = document.getElementById("nationalitySelect");

cancelCreate.addEventListener("click", () => closeCreate());
createForm.addEventListener("submit", (e) => {
  e.preventDefault();
  const form = new FormData(createForm);
  const payload = {
    cid: Number(createForm.dataset.cid),
    firstname: (form.get("firstname") || "").trim(),
    lastname:  (form.get("lastname")  || "").trim(),
    birthdate: (form.get("birthdate") || "").trim(),
    nationality:(form.get("nationality")|| "").trim(),
    gender:    (form.get("gender")     || "").trim(),
  };
  nui("char_create", payload);
});

function openCreate(cid) {
  modal.style.display = "grid";
  createForm.dataset.cid = cid;
  nui("char_enable_blur");
}
function closeCreate() {
  modal.style.display = "none";
  nui("char_disable_blur");
}

const detailsModal = document.getElementById("details");
const closeDetails  = document.getElementById("detailsClose");
const detLogo  = document.getElementById("idBadge");
const detName  = document.getElementById("idName");
const detCID   = document.getElementById("idCitizen");
const detJob   = document.getElementById("idJob");
const detGrade = document.getElementById("idGrade");
const detGender= document.getElementById("idGender");
const detDOB   = document.getElementById("idDOB");
const detNation= document.getElementById("idNat");
const detPhone = document.getElementById("idPhone");
const detCash  = document.getElementById("idCash");
const detBank  = document.getElementById("idBank");
if (closeDetails) closeDetails.addEventListener("click", () => (detailsModal.style.display = "none"));

function openDetails(c) {
  if (!detailsModal) return;
  detName.textContent   = c.name || "—";
  detCID.textContent    = c.citizenid || "—";
  detJob.textContent    = c.job || "Civilian";
  detGrade.textContent  = c.grade || "—";
  detGender.textContent = c.gender || "—";
  detDOB.textContent    = c.birthdate || "—";
  detNation.textContent = c.nationality || "—";
  detPhone.textContent  = c.phone || "—";
  detCash.textContent   = `$${Number(c.cash || 0).toLocaleString()}`;
  detBank.textContent   = `$${Number(c.bank || 0).toLocaleString()}`;
  const jobKey = jobKeyFrom(c.job_key || c.job || "unemployed");
  if (detLogo){
    detLogo.src = `logo/${jobKey}.png`;
    detLogo.alt = c.job || "Civilian";
    detLogo.onerror = () => (detLogo.src = `logo/unemployed.png`);
  }
  detailsModal.style.display = "grid";
}

const confirmModal = document.getElementById("confirm");
const cancelDelete = document.getElementById("confirmCancel");
const confirmDeleteBtn = document.getElementById("confirmYes");
let pendingDelete = null;

if (cancelDelete) cancelDelete.addEventListener("click", () => {
  confirmModal.style.display = "none";
  pendingDelete = null;
});
if (confirmDeleteBtn) confirmDeleteBtn.addEventListener("click", async () => {
  if (!pendingDelete) return;
  await nui("char_delete", { citizenid: pendingDelete });
  confirmModal.style.display = "none";
  pendingDelete = null;
});
function openConfirm(_name, citizenid) {
  if (!confirmModal) return;
  pendingDelete = citizenid;
  confirmModal.style.display = "grid";
}

const el = (tag, cls, text) => {
  const n = document.createElement(tag);
  if (cls) n.className = cls;
  if (text) n.textContent = text;
  return n;
};
const jobKeyFrom = (s) =>
  String(s || "")
    .toLowerCase()
    .replace(/—/g, "-")
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");

// Flags: PNG first (most packs), SVG fallback
function flagFileFrom(nation) {
  const key  = normalizeKey(nation || FLAG_DEFAULT);
  const code = EXTRA_DEMONYMS[key] || COUNTRY_INDEX[key] || key;
  return { png: `${FLAG_DIR}/${code}.png`, svg: `${FLAG_DIR}/${code}.svg` };
}

/* Identical-sized SVGs for the 3 actions */
const icons = {
  play:  `<svg viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>`,
  info:  `<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="8"/></svg>`,
  trash: `<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2"/></svg>`
};

function renderCards(characters) {
  LAST_CHARACTERS = characters;
  dock.innerHTML = "";
  characters.forEach((c) => {
    if (c.empty) {
      const card = el("div", "cardlet empty");
      card.appendChild(el("h3", "", "New Character"));
      const btn = el("button", "btn primary create", "Create");
      btn.addEventListener("click", () => openCreate(c.idx));
      card.appendChild(btn);
      dock.appendChild(card);
      return;
    }
    const card = el("div", "cardlet");
    const head = el("div", "card-head");
    const avatar = el("div", "avatar");
    const avImg = new Image();
    avImg.src = AVATAR_ICON; avImg.alt = "avatar";
    avatar.appendChild(avImg);
    head.appendChild(avatar);
    const title = el("div", "title");
    const fullName = String(c.name || "").trim();
    const parts = fullName.split(/\s+/);
    const first = parts[0] || "—";
    const last  = parts.length > 1 ? parts.slice(1).join(" ") : "—";
    const firstEl = el("div", "first", first); firstEl.title = fullName;
    const lastEl  = el("div", "last",  last ); lastEl.title  = fullName;
    const cidEl   = el("div", "cid",   c.citizenid || "—"); cidEl.title = c.citizenid || "";
    title.append(firstEl, lastEl, cidEl);
    head.appendChild(title);
    const row = el("div", "row icon-list");
    const jobIcon = el("div", "icon job");
    const jobImg  = new Image();
    const jobKey  = jobKeyFrom(c.job_key || c.job || "unemployed");
    jobImg.src = `logo/${jobKey}.png`; jobImg.alt = c.job || "Civilian";
    jobImg.onerror = () => (jobImg.src = `logo/unemployed.png`);
    jobIcon.appendChild(jobImg); row.appendChild(jobIcon);
    const flagIcon = el("div", "icon flag");
    const fk = flagFileFrom(c.nationality || FLAG_DEFAULT);
    const flagImg = new Image();
    flagImg.src = fk.png; flagImg.alt = c.nationality || "—";
    flagImg.onerror = () => (flagImg.src = fk.svg);
    flagIcon.appendChild(flagImg); row.appendChild(flagIcon);
    if (USE_GENDER_PILL) {
      const genderIcon = el("div", "icon gender");
      const g = (c.gender || "").toLowerCase().includes("female") ? "female" : "male";
      const gImg = new Image();
      gImg.src = `gender/${g}.svg`; gImg.alt = g;
      gImg.onerror = () => (gImg.src = `gender/${g}.png`);
      genderIcon.appendChild(gImg); row.appendChild(genderIcon);
    }
    const top = el("div", "topband");
    top.appendChild(head);
    top.appendChild(row);
    const actions = el("div", "actions inline");
    const play = el("button", "btn icon play", "");     play.innerHTML = icons.play;  play.title = "Play";
    const det  = el("button", "btn icon secondary",""); det.innerHTML = icons.info;  det.title = "Details";
    const del  = el("button", "btn icon delete",   ""); del.innerHTML = icons.trash; del.title = "Delete";
    play.addEventListener("click", () => nui("char_play", { citizenid: c.citizenid }));
    det.addEventListener("click",  () => openDetails(c));
    del.addEventListener("click",  () => openConfirm(c.name || "Character", c.citizenid));
    actions.append(play, det, del);
    top.appendChild(actions);
    card.appendChild(top);
    card.addEventListener("mouseenter", () => nui("char_preview", { citizenid: c.citizenid }));
    card.addEventListener("click",      () => nui("char_preview", { citizenid: c.citizenid }));
    dock.appendChild(card);
  });
}

window.addEventListener("message", (e) => {
  const d = e.data;
  if (!d || !d.type) return;
  if (d.type === "char:open") {
    nationalitySelect.innerHTML = `<option value="" disabled selected>Select nationality</option>`;
    (d.nationalityOptions || []).forEach((n) => {
      const opt = document.createElement("option");
      opt.value = n; opt.textContent = n;
      nationalitySelect.appendChild(opt);
    });
    renderCards(d.characters || []);
    root.classList.remove("hidden");
    nui("ui_ready");
    return;
  }
  if (d.type === "char:close") {
    root.classList.add("hidden");
    closeCreate();
    const details = document.getElementById("details");
    const confirm = document.getElementById("confirm");
    if (details) details.style.display = "none";
    if (confirm) confirm.style.display = "none";
    return;
  }
  if (d.type === "char:force-close-modal") {
    closeCreate();
    return;
  }
});
