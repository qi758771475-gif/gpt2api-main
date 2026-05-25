import { Suspense, lazy } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';

import { AppLayout } from './layouts/AppLayout';
import { AuthLayout } from './layouts/AuthLayout';
import { LoadingScreen } from './components/LoadingScreen';
import { LoginGate } from './components/LoginGate';
import { Toaster } from './components/Toaster';
import { RequireAuth } from './routes/RequireAuth';

const LoginPage = lazy(() => import('./pages/auth/LoginPage'));
const RegisterPage = lazy(() => import('./pages/auth/RegisterPage'));
const CreateStudioPage = lazy(() => import('./pages/create/CreateStudioPage'));
const HistoryPage = lazy(() => import('./pages/create/HistoryPage'));
const BillingPage = lazy(() => import('./pages/billing/BillingPage'));
const KeysPage = lazy(() => import('./pages/keys/KeysPage'));
const DocsPage = lazy(() => import('./pages/keys/DocsPage'));
const InvitePage = lazy(() => import('./pages/invite/InvitePage'));
const SettingsPage = lazy(() => import('./pages/settings/SettingsPage'));

const urlParams = new URLSearchParams(window.location.search);
const isEmbedded = urlParams.get('mode') === 'embedded' || !!urlParams.get('token');

// In embedded mode, store sub2api token for API authentication
// and clear any stale gpt2api JWT to prevent AuthJWT from
// trying to validate an expired token instead of using Sub2APIAuth.
if (isEmbedded) {
  const tok = urlParams.get('token');
  if (tok) {
    try { localStorage.setItem('sub2api_token', tok); } catch {}
  }
  try { localStorage.removeItem('klein:token'); } catch {}
}

export default function App() {
  const embedded = isEmbedded;

  return (
    <>
      <Toaster />
      {!embedded && <LoginGate />}
      <Suspense fallback={<LoadingScreen />}>
        <Routes>
          {!embedded && (
            <Route element={<AuthLayout />}>
              <Route path="/login" element={<LoginPage />} />
              <Route path="/register" element={<RegisterPage />} />
            </Route>
          )}

          <Route element={<AppLayout embedded={embedded} />}>
            <Route path="/" element={<Navigate to="/create/image" replace />} />
            <Route path="/create/image" element={<CreateStudioPage />} />
            <Route path="/create/text" element={<CreateStudioPage />} />
            <Route path="/create/video" element={<CreateStudioPage />} />
            <Route path="/docs" element={<DocsPage />} />

            {embedded ? (
              <>
                <Route path="/history" element={<HistoryPage />} />
                <Route path="/settings" element={<SettingsPage />} />
              </>
            ) : (
              <Route element={<RequireAuth />}>
                <Route path="/history" element={<HistoryPage />} />
                <Route path="/billing" element={<BillingPage />} />
                <Route path="/keys" element={<KeysPage />} />
                <Route path="/invite" element={<InvitePage />} />
                <Route path="/settings" element={<SettingsPage />} />
              </Route>
            )}
          </Route>

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Suspense>
    </>
  );
}
