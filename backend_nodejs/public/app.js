// =============================================================================
// المحاكي التفاعلي لمنظومة العلاج الطبيعي المنزلي (3 تطبيقات متزامنة)
// =============================================================================

let globalState = null;
let currentPatientTab = 'book';
let currentAdminTab = 'queue';
let currentTherapistTab = 'tasks';

// تهيئة الأيقونات والاتصال
document.addEventListener('DOMContentLoaded', () => {
  initView();
  if (window.lucide) lucide.createIcons();
  fetchState();
  setInterval(fetchState, 2000); // تحديث دوري كل ثانيتين للمزامنة اللحظية
});

function initView() {
  const params = new URLSearchParams(window.location.search);
  const view = params.get('view');
  if (view === 'patient') {
    document.getElementById('col-admin').classList.add('hidden');
    document.getElementById('col-therapist').classList.add('hidden');
    const pFrame = document.querySelector('#col-patient .phone-frame');
    if (pFrame) {
      pFrame.style.width = '100vw';
      pFrame.style.height = '100vh';
      pFrame.style.border = 'none';
      pFrame.style.borderRadius = '0';
    }
    const notch = document.querySelector('#col-patient .phone-notch');
    if (notch) notch.classList.add('hidden');
    const hdr = document.querySelector('header');
    if (hdr) hdr.classList.add('hidden');
    const main = document.querySelector('main');
    if (main) {
      main.classList.remove('p-6');
      main.classList.add('p-0');
    }
  } else if (view === 'admin') {
    document.getElementById('col-patient').classList.add('hidden');
    document.getElementById('col-therapist').classList.add('hidden');
    const adm = document.getElementById('col-admin');
    if (adm) {
      adm.style.width = '100vw';
      adm.style.height = '100vh';
      adm.style.border = 'none';
      adm.style.borderRadius = '0';
    }
    const hdr = document.querySelector('header');
    if (hdr) hdr.classList.add('hidden');
    const main = document.querySelector('main');
    if (main) {
      main.classList.remove('p-6');
      main.classList.add('p-0');
    }
  } else if (view === 'therapist') {
    document.getElementById('col-patient').classList.add('hidden');
    document.getElementById('col-admin').classList.add('hidden');
    const thFrame = document.querySelector('#col-therapist .phone-frame');
    if (thFrame) {
      thFrame.style.width = '100vw';
      thFrame.style.height = '100vh';
      thFrame.style.border = 'none';
      thFrame.style.borderRadius = '0';
    }
    const notch = document.querySelector('#col-therapist .phone-notch');
    if (notch) notch.classList.add('hidden');
    const hdr = document.querySelector('header');
    if (hdr) hdr.classList.add('hidden');
    const main = document.querySelector('main');
    if (main) {
      main.classList.remove('p-6');
      main.classList.add('p-0');
    }
  }
}

function openWifiModal() {
  document.getElementById('wifi-modal').classList.remove('hidden');
}

function closeWifiModal() {
  document.getElementById('wifi-modal').classList.add('hidden');
}

// جلب الحالة الكاملة من الخادم
async function fetchState() {
  try {
    const res = await fetch('/api/all-state');
    if (!res.ok) return;
    globalState = await res.json();
    renderAll();
  } catch (err) {
    console.error('Error fetching state:', err);
  }
}

// عرض جميع الواجهات
function renderAll() {
  if (!globalState) return;
  renderPatientApp();
  renderAdminApp();
  renderTherapistApp();
  if (window.lucide) lucide.createIcons();
}

// -----------------------------------------------------------------------------
// 1. منطق وعرض تطبيق المريض (Patient App)
// -----------------------------------------------------------------------------
function switchPatientTab(tab) {
  currentPatientTab = tab;
  document.getElementById('p-tab-book').classList.toggle('hidden', tab !== 'book');
  document.getElementById('p-tab-orders').classList.toggle('hidden', tab !== 'orders');
  document.getElementById('p-tab-file').classList.toggle('hidden', tab !== 'file');

  ['book', 'orders', 'file'].forEach((t) => {
    const btn = document.getElementById(`p-tab-btn-${t}`);
    if (t === tab) {
      btn.className = 'flex-1 py-2.5 text-center text-teal-700 border-b-2 border-teal-600 font-bold';
    } else {
      btn.className = 'flex-1 py-2.5 text-center text-slate-500 hover:text-slate-800';
    }
  });

  if (window.lucide) lucide.createIcons();
}

function updatePatientPrice() {
  const sType = document.getElementById('p-service').value;
  const pDisp = document.getElementById('p-price-display');
  if (sType === 'single') pDisp.textContent = '70 د.ل (نقداً)';
  else if (sType === 'assessment') pDisp.textContent = '80 د.ل (نقداً)';
  else if (sType === 'package_6') pDisp.textContent = '360 د.ل (باقة 6 جلسات)';
}

async function submitPatientBooking() {
  const service = document.getElementById('p-service');
  const specialty = document.getElementById('p-specialty').value;
  const gender = document.getElementById('p-gender').value;
  const district = document.getElementById('p-district').value;
  const address = document.getElementById('p-address').value;

  let price = 70.0;
  let serviceLabel = 'جلسة علاجية منزلية مفردة';
  let paymentMethod = 'cash';

  if (service.value === 'assessment') {
    price = 80.0;
    serviceLabel = 'كشف وتقييم شامل للحالة';
  } else if (service.value === 'package_6') {
    price = 360.0;
    serviceLabel = 'باقة تأهيل متكاملة (6 جلسات)';
    paymentMethod = 'package';
  }

  const payload = {
    patient_id: '11111111-1111-1111-1111-111111111111',
    patient_name: 'خالد المبروك',
    patient_phone: '091-4829104',
    service_type: service.value,
    service_label: serviceLabel,
    specialty_needed: specialty,
    preferred_gender: gender,
    district: district,
    address_notes: address,
    scheduled_label: 'اليوم في أقرب وقت متاح',
    price: price,
    payment_method: paymentMethod,
  };

  try {
    const res = await fetch('/api/visits', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    if (res.ok) {
      await fetchState();
      switchPatientTab('orders');
    }
  } catch (err) {
    alert('تعذر إرسال الطلب: ' + err.message);
  }
}

function renderPatientApp() {
  const container = document.getElementById('p-active-order-container');
  const historyContainer = document.getElementById('p-medical-history');

  const myOrders = globalState.visits.filter(
    (v) => v.patient_id === '11111111-1111-1111-1111-111111111111'
  );

  const activeOrder = myOrders.find((v) => v.status !== 'completed' && v.status !== 'cancelled') || myOrders[0];

  if (!activeOrder) {
    container.innerHTML = `
      <div class="text-center py-8 text-slate-400">
        <i data-lucide="calendar-check" class="w-10 h-10 mx-auto mb-2 text-slate-300"></i>
        <div>لا يوجد طلب نشط حالياً. اضغط "طلب زيارة" لحجز جلستك!</div>
      </div>
    `;
  } else {
    const statusMap = {
      pending_review: { label: 'قيد مراجعة المركز', step: 1, color: 'amber' },
      dispatched: { label: 'تم توجيه الطلب للأخصائي', step: 2, color: 'blue' },
      accepted: { label: 'تم قبول الزيارة من الأخصائي', step: 3, color: 'indigo' },
      en_route: { label: 'الأخصائي في الطريق إليك', step: 4, color: 'teal' },
      in_session: { label: 'الجلسة جارية بالمنزل حالياً', step: 5, color: 'purple' },
      completed: { label: 'اكتملت الزيارة بنجاح', step: 6, color: 'emerald' },
    };

    const cur = statusMap[activeOrder.status] || { label: activeOrder.status, step: 1, color: 'slate' };

    container.innerHTML = `
      <div class="bg-white border rounded-2xl p-4 shadow-sm space-y-3">
        <div class="flex items-center justify-between border-b pb-2">
          <div>
            <span class="font-extrabold text-teal-800 text-xs">${activeOrder.order_code}</span>
            <div class="text-[11px] text-slate-500">${activeOrder.service_label}</div>
          </div>
          <span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-${cur.color}-100 text-${cur.color}-800">
            ${cur.label}
          </span>
        </div>

        <!-- 6-Stage Stepper -->
        <div class="space-y-2 py-1">
          ${renderStepItem(1, '1. مراجعة وتأكيد موظف المركز', cur.step >= 1, cur.step === 1)}
          ${renderStepItem(2, '2. تحويل الطلب للأخصائي المتاح', cur.step >= 2, cur.step === 2)}
          ${renderStepItem(3, `3. قبول الأخصائي (${activeOrder.therapist_name || 'بانتظار القبول'})`, cur.step >= 3, cur.step === 3)}
          ${renderStepItem(4, '4. الأخصائي في الطريق لمنزلك (فتح المسار)', cur.step >= 4, cur.step === 4)}
          ${renderStepItem(5, '5. بدء الجلسة العلاجية (GPS Check-in)', cur.step >= 5, cur.step === 5)}
          ${renderStepItem(6, '6. إتمام الجلسة وحفظ التقرير الطبي', cur.step >= 6, cur.step === 6)}
        </div>

        <div class="bg-slate-50 p-2.5 rounded-xl border text-[11px] space-y-1">
          <div class="flex justify-between">
            <span class="text-slate-500">المعالج:</span>
            <span class="font-bold text-slate-800">${activeOrder.therapist_name || 'يتم التحديد بواسطة موظف المركز'}</span>
          </div>
          <div class="flex justify-between">
            <span class="text-slate-500">المبلغ المطلوب:</span>
            <span class="font-bold text-teal-700">${activeOrder.price} د.ل (${activeOrder.payment_method === 'package' ? 'ضمن الباقة' : 'نقداً'})</span>
          </div>
        </div>
      </div>
    `;
  }

  // Completed Visits (Medical History)
  const completedList = myOrders.filter((v) => v.status === 'completed');
  if (completedList.length === 0) {
    historyContainer.innerHTML = '<div class="text-slate-400 text-center py-4">لا توجد تقارير سابقة بعد.</div>';
  } else {
    historyContainer.innerHTML = completedList
      .map(
        (v) => `
      <div class="bg-white border rounded-xl p-3 shadow-sm space-y-2">
        <div class="flex justify-between items-center border-b pb-1">
          <span class="font-bold text-teal-800">${v.service_label}</span>
          <span class="text-[10px] text-slate-400">${new Date(v.created_at).toLocaleDateString('ar-LY')}</span>
        </div>
        <div>
          <div class="text-slate-500 text-[10px]">ملاحظات الأخصائي (${v.therapist_name}):</div>
          <div class="font-semibold text-slate-800 text-[11px]">${v.clinical_notes || 'تحسن مستمر'}</div>
        </div>
        <div class="bg-amber-50 p-2 rounded-lg border border-amber-200">
          <div class="text-amber-900 text-[10px] font-bold">التمارين المنزلية المطلوبة:</div>
          <div class="text-amber-800 text-[11px]">${v.home_exercises || 'تكرار التمارين الموصوفة مرتين يومياً'}</div>
        </div>
        <div class="flex items-center justify-between pt-1">
          <span class="text-[10px] text-slate-500">تقييمك للجلسة:</span>
          <div class="flex gap-1 text-amber-500">
            ${[1, 2, 3, 4, 5]
              .map(
                (star) => `
              <span onclick="rateVisit('${v.id}', ${star})" class="cursor-pointer ${
                  (v.patient_rating || 5) >= star ? 'text-amber-500' : 'text-slate-300'
                }">★</span>
            `
              )
              .join('')}
          </div>
        </div>
      </div>
    `
      )
      .join('');
  }
}

function renderStepItem(num, label, isDone, isCurrent) {
  let iconClass = 'bg-slate-200 text-slate-400';
  if (isDone) iconClass = 'bg-emerald-600 text-white';
  if (isCurrent && !isDone) iconClass = 'bg-amber-500 text-white animate-pulse';

  return `
    <div class="flex items-center gap-2.5">
      <div class="w-5 h-5 rounded-full ${iconClass} flex items-center justify-center text-[10px] font-bold shrink-0">
        ${isDone ? '✓' : num}
      </div>
      <span class="text-[11px] ${isCurrent ? 'font-bold text-teal-900' : isDone ? 'text-slate-700' : 'text-slate-400'}">
        ${label}
      </span>
    </div>
  `;
}

async function rateVisit(id, rating) {
  await fetch(`/api/visits/${id}/rate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ rating }),
  });
  fetchState();
}

// -----------------------------------------------------------------------------
// 2. منطق وعرض شاشة استقبال وإدارة المركز (Admin Dashboard)
// -----------------------------------------------------------------------------
function switchAdminTab(tab) {
  currentAdminTab = tab;
  ['queue', 'staff', 'custody', 'settings'].forEach((t) => {
    document.getElementById(`adm-tab-${t}`).classList.toggle('hidden', t !== tab);
    const btn = document.getElementById(`adm-tab-btn-${t}`);
    if (t === tab) {
      btn.className = 'py-3 border-b-2 border-teal-600 text-teal-700 flex items-center gap-1.5';
    } else {
      btn.className = 'py-3 text-slate-500 hover:text-slate-800 flex items-center gap-1.5';
    }
  });

  if (tab === 'settings' && globalState) {
    document.getElementById('adm-setting-name').value = globalState.settings.center_name;
    document.getElementById('adm-setting-price-single').value = globalState.settings.single_session_price;
    document.getElementById('adm-setting-commission').value = globalState.settings.center_commission_pct;
    document.getElementById('adm-setting-auto-dispatch').checked = globalState.settings.auto_dispatch;
  }

  if (window.lucide) lucide.createIcons();
}

function renderAdminApp() {
  const pendingOrders = globalState.visits.filter((v) => v.status === 'pending_review');
  const onlineTherapists = globalState.therapists.filter((t) => t.is_online);
  const activeVisits = globalState.visits.filter(
    (v) => v.status === 'dispatched' || v.status === 'accepted' || v.status === 'en_route' || v.status === 'in_session'
  );
  const totalCustody = globalState.therapists.reduce((acc, t) => acc + (t.cash_custody_balance || 0), 0);

  document.getElementById('stat-pending').textContent = pendingOrders.length;
  document.getElementById('stat-online-therapists').textContent = onlineTherapists.length;
  document.getElementById('stat-active-visits').textContent = activeVisits.length;
  document.getElementById('stat-custody-total').textContent = `${totalCustody.toFixed(0)} د.ل`;

  // Render Queue
  const queueContainer = document.getElementById('admin-orders-list');
  queueContainer.innerHTML = globalState.visits
    .map((v) => {
      let badge = '';
      if (v.status === 'pending_review')
        badge = '<span class="px-2 py-0.5 rounded-full bg-amber-100 text-amber-800 font-bold">بانتظار التوجيه</span>';
      else if (v.status === 'dispatched')
        badge = '<span class="px-2 py-0.5 rounded-full bg-blue-100 text-blue-800 font-bold">تم التوجيه (بانتظار قبول الأخصائي)</span>';
      else if (v.status === 'accepted')
        badge = '<span class="px-2 py-0.5 rounded-full bg-indigo-100 text-indigo-800 font-bold">تم القبول</span>';
      else if (v.status === 'en_route')
        badge = '<span class="px-2 py-0.5 rounded-full bg-teal-100 text-teal-800 font-bold">الأخصائي في الطريق</span>';
      else if (v.status === 'in_session')
        badge = '<span class="px-2 py-0.5 rounded-full bg-purple-100 text-purple-800 font-bold">الجلسة جارية</span>';
      else if (v.status === 'completed')
        badge = '<span class="px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 font-bold">مكتملة ✓</span>';

      return `
      <div class="bg-white border rounded-xl p-3 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-3 text-xs">
        <div class="space-y-1">
          <div class="flex items-center gap-2">
            <span class="font-extrabold text-teal-800">${v.order_code}</span>
            <span class="font-bold text-slate-800">${v.patient_name} (${v.patient_phone})</span>
            ${badge}
          </div>
          <div class="text-slate-500">
            ${v.service_label} • <strong>${v.specialty_needed}</strong> • ${v.district} (${v.address_notes})
          </div>
          <div class="text-[11px] text-slate-400">
            الأخصائي المعين: <strong class="text-indigo-900">${v.therapist_name || 'لم يحدد بعد'}</strong> • المبلغ: ${v.price} د.ل (${v.payment_method})
          </div>
          ${
            v.rejection_reason
              ? `<div class="text-red-600 bg-red-50 p-1.5 rounded font-semibold text-[11px]">اعتذار الأخصائي: ${v.rejection_reason}</div>`
              : ''
          }
        </div>

        ${
          v.status === 'pending_review'
            ? `
          <div class="flex items-center gap-2 shrink-0">
            <select id="dispatch-select-${v.id}" class="border rounded-lg p-2 bg-slate-50 text-xs">
              ${globalState.therapists
                .map(
                  (t) => `
                <option value="${t.id}" ${t.is_online ? '' : 'disabled'}>
                  ${t.name} (${t.is_online ? 'متصل' : 'غير متصل'}) - ${t.district}
                </option>
              `
                )
                .join('')}
            </select>
            <button onclick="adminDispatchOrder('${v.id}')" class="px-3 py-2 bg-teal-600 hover:bg-teal-700 text-white font-bold rounded-lg transition shadow">
              توجيه للأخصائي
            </button>
          </div>
        `
            : ''
        }
      </div>
    `;
    })
    .join('');

  // Render Staff
  const staffContainer = document.getElementById('admin-therapists-list');
  staffContainer.innerHTML = globalState.therapists
    .map(
      (t) => `
    <div class="bg-white border rounded-xl p-3 shadow-sm space-y-2 text-xs">
      <div class="flex items-center justify-between border-b pb-2">
        <div>
          <span class="font-bold text-slate-800 text-sm">${t.name}</span>
          <div class="text-[11px] text-slate-500">${t.specialty}</div>
        </div>
        <span class="px-2 py-0.5 rounded-full text-[10px] font-bold ${
          t.is_online ? 'bg-emerald-100 text-emerald-800' : 'bg-slate-100 text-slate-500'
        }">
          ${t.is_online ? 'متصل ومتاح' : 'غير متصل'}
        </span>
      </div>
      <div class="grid grid-cols-2 gap-2 text-[11px]">
        <div>نطاق التغطية: <strong>${t.district}</strong></div>
        <div>الهاتف: <strong>${t.phone}</strong></div>
        <div>الجلسات المنفذة: <strong>${t.completed_sessions_count}</strong></div>
        <div>التقييم العام: <strong class="text-amber-600">★ ${t.rating}</strong></div>
      </div>
      <div class="bg-slate-50 p-2 rounded-lg flex justify-between items-center">
        <span>عهدة الكاش باليد:</span>
        <strong class="text-amber-700 font-bold">${t.cash_custody_balance} د.ل</strong>
      </div>
    </div>
  `
    )
    .join('');

  // Render Custody Settlements
  const custodyContainer = document.getElementById('admin-custody-list');
  custodyContainer.innerHTML = globalState.therapists
    .map((t) => {
      const centerShare = t.cash_custody_balance * (globalState.settings.center_commission_pct / 100);
      const therapistNet = t.cash_custody_balance - centerShare;
      return `
      <div class="bg-white border rounded-xl p-3 shadow-sm flex items-center justify-between gap-4 text-xs">
        <div>
          <div class="font-bold text-slate-800 text-sm">${t.name}</div>
          <div class="text-slate-500 text-[11px]">إجمالي الكاش المحصل بعهدة الأخصائي: <strong class="text-amber-700 text-xs">${t.cash_custody_balance} د.ل</strong></div>
          <div class="text-[11px] text-slate-600 mt-1">
            حصة المركز المستحقة (40%): <strong class="text-teal-700">${centerShare.toFixed(1)} د.ل</strong> • صافي الأخصائي (60%): <strong>${therapistNet.toFixed(1)} د.ل</strong>
          </div>
        </div>

        <button onclick="adminSettleCustody('${t.id}')" ${t.cash_custody_balance === 0 ? 'disabled' : ''} class="px-4 py-2 ${
        t.cash_custody_balance > 0 ? 'bg-emerald-600 hover:bg-emerald-700 text-white' : 'bg-slate-200 text-slate-400'
      } font-bold rounded-lg transition shadow">
          تصفية العهدة واستلام حصة المركز
        </button>
      </div>
    `;
    })
    .join('');
}

async function adminDispatchOrder(orderId) {
  const sel = document.getElementById(`dispatch-select-${orderId}`);
  const therapistId = sel.value;
  await fetch('/api/admin/dispatch', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ order_id: orderId, therapist_id: therapistId }),
  });
  fetchState();
}

async function adminSettleCustody(therapistId) {
  await fetch('/api/admin/settle-custody', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ therapist_id: therapistId }),
  });
  fetchState();
}

async function saveAdminSettings() {
  const payload = {
    center_name: document.getElementById('adm-setting-name').value,
    single_session_price: Number(document.getElementById('adm-setting-price-single').value),
    center_commission_pct: Number(document.getElementById('adm-setting-commission').value),
    auto_dispatch: document.getElementById('adm-setting-auto-dispatch').checked,
  };
  await fetch('/api/admin/settings', {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  alert('تم حفظ الإعدادات وتحديثها في المنظومة بنجاح!');
  fetchState();
}

// -----------------------------------------------------------------------------
// 3. منطق وعرض تطبيق الأخصائي (Therapist App - Dr. Ahmed)
// -----------------------------------------------------------------------------
function switchTherapistTab(tab) {
  currentTherapistTab = tab;
  document.getElementById('th-tab-tasks').classList.toggle('hidden', tab !== 'tasks');
  document.getElementById('th-tab-wallet').classList.toggle('hidden', tab !== 'wallet');

  ['tasks', 'wallet'].forEach((t) => {
    const btn = document.getElementById(`th-tab-btn-${t}`);
    if (t === tab) {
      btn.className = 'flex-1 py-2.5 text-center text-indigo-700 border-b-2 border-indigo-600 font-bold';
    } else {
      btn.className = 'flex-1 py-2.5 text-center text-slate-500 hover:text-slate-800';
    }
  });

  if (window.lucide) lucide.createIcons();
}

async function toggleTherapistOnline() {
  const chk = document.getElementById('th-online-toggle');
  await fetch('/api/therapists/33333333-3333-3333-3333-333333333331/status', {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ is_online: chk.checked }),
  });
  fetchState();
}

function renderTherapistApp() {
  const th = globalState.therapists.find((item) => item.id === '33333333-3333-3333-3333-333333333331');
  if (!th) return;

  // Online indicator
  document.getElementById('th-online-indicator').className = `w-2.5 h-2.5 rounded-full ${
    th.is_online ? 'bg-emerald-400 animate-pulse' : 'bg-slate-400'
  }`;
  document.getElementById('th-online-text').textContent = th.is_online ? 'متاح للزيارات' : 'غير متصل';
  document.getElementById('th-online-toggle').checked = th.is_online;

  // Wallet
  document.getElementById('th-wallet-custody').textContent = `${th.cash_custody_balance.toFixed(2)} د.ل`;
  document.getElementById('th-completed-count').textContent = th.completed_sessions_count;
  document.getElementById('th-total-earned').textContent = `${th.total_earned.toFixed(0)} د.ل`;

  // Tasks
  const myTasks = globalState.visits.filter((v) => v.therapist_id === th.id && v.status !== 'completed');
  const taskContainer = document.getElementById('therapist-active-tasks');

  if (myTasks.length === 0) {
    taskContainer.innerHTML = `
      <div class="text-center py-10 text-slate-400">
        <i data-lucide="inbox" class="w-10 h-10 mx-auto mb-2 text-slate-300"></i>
        <div>لا توجد مهام مسندة إليك حالياً.</div>
        <div class="text-[11px] text-slate-400 mt-1">عند توجيه طلب جديد من موظف المركز سيظهر هنا فوراً.</div>
      </div>
    `;
  } else {
    taskContainer.innerHTML = myTasks
      .map(
        (v) => `
      <div class="bg-white border rounded-2xl p-4 shadow-sm space-y-3">
        <div class="flex items-center justify-between border-b pb-2">
          <div>
            <div class="font-extrabold text-indigo-900 text-sm">${v.patient_name}</div>
            <div class="text-[11px] text-slate-500">${v.patient_phone}</div>
          </div>
          <span class="px-2 py-0.5 rounded-full text-[10px] font-bold bg-indigo-100 text-indigo-800">
            ${v.order_code}
          </span>
        </div>

        <div class="space-y-1 text-[11px] text-slate-600">
          <div>الخدمة: <strong>${v.service_label}</strong></div>
          <div>العنوان: <strong>${v.district}</strong> - ${v.address_notes}</div>
          <div>التحصيل المطلوب: <strong class="text-teal-700">${v.price} د.ل (${v.payment_method === 'package' ? 'مدفوع بالباقة' : 'نقداً'})</strong></div>
        </div>

        <!-- Action Buttons based on Status -->
        <div class="pt-2 border-t">
          ${renderTherapistAction(v)}
        </div>
      </div>
    `
      )
      .join('');
  }
}

function renderTherapistAction(v) {
  if (v.status === 'dispatched') {
    return `
      <div class="grid grid-cols-2 gap-2">
        <button onclick="updateVisitStatus('${v.id}', 'accepted')" class="py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl transition flex items-center justify-center gap-1.5 shadow">
          <span>قبول الزيارة</span>
        </button>
        <button onclick="rejectVisit('${v.id}')" class="py-2.5 bg-rose-50 text-rose-700 hover:bg-rose-100 font-bold rounded-xl border border-rose-200 transition">
          اعتذار
        </button>
      </div>
    `;
  }

  if (v.status === 'accepted') {
    return `
      <button onclick="updateVisitStatus('${v.id}', 'en_route')" class="w-full py-2.5 bg-indigo-700 hover:bg-indigo-800 text-white font-bold rounded-xl transition flex items-center justify-center gap-2 shadow">
        <i data-lucide="navigation" class="w-4 h-4"></i>
        بدء التحرك للمريض (فتح الخريطة)
      </button>
    `;
  }

  if (v.status === 'en_route') {
    return `
      <button onclick="updateVisitStatus('${v.id}', 'in_session')" class="w-full py-2.5 bg-teal-600 hover:bg-teal-700 text-white font-bold rounded-xl transition flex items-center justify-center gap-2 shadow animate-pulse">
        <i data-lucide="map-pin" class="w-4 h-4"></i>
        تسجيل الوصول وبدء الجلسة (GPS Check-in)
      </button>
    `;
  }

  if (v.status === 'in_session') {
    return `
      <div class="space-y-2">
        <div class="font-bold text-slate-800 text-[11px]">التقرير الطبي وتوصيات الجلسة:</div>
        <textarea id="th-notes-${v.id}" class="w-full border rounded-lg p-2 text-xs bg-slate-50" rows="2" placeholder="تقييم الحالة، قياس زاوية المفصل، مدى الاستجابة..."></textarea>
        <input type="text" id="th-exercises-${v.id}" class="w-full border rounded-lg p-2 text-xs bg-slate-50" placeholder="التمارين المنزلية المطلوبة من المريض..." />
        <button onclick="completeVisit('${v.id}')" class="w-full py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl transition flex items-center justify-center gap-2 shadow">
          <i data-lucide="check-circle" class="w-4 h-4"></i>
          إنهاء الجلسة وتأكيد استلام (${v.price} د.ل)
        </button>
      </div>
    `;
  }

  return '';
}

async function updateVisitStatus(id, status) {
  await fetch(`/api/visits/${id}/status`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status }),
  });
  fetchState();
}

async function rejectVisit(id) {
  await fetch(`/api/visits/${id}/reject`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ reason: 'اعتذر الأخصائي لظرف طارئ' }),
  });
  fetchState();
}

async function completeVisit(id) {
  const notes = document.getElementById(`th-notes-${id}`).value;
  const exercises = document.getElementById(`th-exercises-${id}`).value;
  await fetch(`/api/visits/${id}/complete`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      therapist_id: '33333333-3333-3333-3333-333333333331',
      clinical_notes: notes || 'تم إتمام التمارين العلاجية للجلسة بنجاح والتوصية بالراحة.',
      home_exercises: exercises || 'تمارين إطالة وتقوية العضلات 3 مرات يومياً.',
    }),
  });
  fetchState();
}

// -----------------------------------------------------------------------------
// إعادة ضبط المحاكاة ونافذة السيناريو
// -----------------------------------------------------------------------------
async function resetDemoState() {
  if (confirm('هل ترغب في إعادة ضبط بيانات العرض التجريبي إلى حالتها الافتراضية؟')) {
    await fetch('/api/reset-demo', { method: 'POST' });
    fetchState();
  }
}

function openScriptModal() {
  document.getElementById('script-modal').classList.remove('hidden');
}

function closeScriptModal() {
  document.getElementById('script-modal').classList.add('hidden');
}
