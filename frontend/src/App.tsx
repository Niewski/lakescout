import { NavLink, Route, Routes } from 'react-router'
import { useQuery } from '@tanstack/react-query'

/**
 * Week 1 shell. Routes are placeholders until week 7; what this proves today is that
 * routing, react-query, Tailwind and the dev proxy to the Spring Boot API all work.
 */

const NAV = [
  { to: '/', label: 'Properties', end: true },
  { to: '/map', label: 'Map' },
  { to: '/preferences', label: 'Preferences' },
  { to: '/admin/jobs', label: 'Jobs' },
]

function ApiStatus() {
  const { data, isPending, isError } = useQuery({
    queryKey: ['health'],
    queryFn: async () => {
      const res = await fetch('/api/actuator/health')
      if (!res.ok) throw new Error(`health check failed: ${res.status}`)
      return (await res.json()) as { status: string }
    },
    retry: false,
  })

  const label = isPending ? 'checking…' : isError ? 'unreachable' : data.status
  const tone = isError ? 'bg-band-pass' : data?.status === 'UP' ? 'bg-band-exceptional' : 'bg-band-tour'

  return (
    <span className="flex items-center gap-2 text-sm">
      <span className={`inline-block size-2 rounded-full ${tone}`} aria-hidden="true" />
      <span>
        API: <span className="font-medium">{label}</span>
      </span>
    </span>
  )
}

function Placeholder({ title }: { title: string }) {
  return (
    <section>
      <h2 className="text-xl font-semibold">{title}</h2>
      <p className="mt-2 text-sm opacity-70">Not built yet.</p>
    </section>
  )
}

export default function App() {
  return (
    <div className="min-h-dvh">
      <header className="border-b border-current/10">
        <div className="mx-auto flex max-w-5xl flex-wrap items-center gap-x-6 gap-y-2 px-4 py-3">
          <span className="font-semibold tracking-tight">LakeScout</span>
          <nav aria-label="Main">
            <ul className="flex gap-4">
              {NAV.map(({ to, label, end }) => (
                <li key={to}>
                  <NavLink
                    to={to}
                    end={end}
                    className={({ isActive }) =>
                      `rounded px-1 py-0.5 text-sm underline-offset-4 focus-visible:outline-2 ${
                        isActive ? 'font-medium underline' : 'opacity-70 hover:opacity-100'
                      }`
                    }
                  >
                    {label}
                  </NavLink>
                </li>
              ))}
            </ul>
          </nav>
          <div className="ms-auto">
            <ApiStatus />
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-5xl px-4 py-8">
        <Routes>
          <Route path="/" element={<Placeholder title="Properties" />} />
          <Route path="/property/:id" element={<Placeholder title="Property detail" />} />
          <Route path="/lake/:id" element={<Placeholder title="Lake detail" />} />
          <Route path="/map" element={<Placeholder title="Map" />} />
          <Route path="/preferences" element={<Placeholder title="Preferences" />} />
          <Route path="/admin/jobs" element={<Placeholder title="Job operations" />} />
          <Route path="*" element={<Placeholder title="Not found" />} />
        </Routes>
      </main>
    </div>
  )
}
