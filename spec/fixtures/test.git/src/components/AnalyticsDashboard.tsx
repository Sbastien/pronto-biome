// New component with a11y issues

interface AnalyticsDashboardProps {
  eventCount: number;
}

export function AnalyticsDashboard({ eventCount }: AnalyticsDashboardProps) {
  return (
    <div>
      <h2>Analytics</h2>

      {/* a11y: img without alt */}
      <img src="/chart.png" />

      {/* a11y: invalid anchor href */}
      <a href="#">View details</a>

      {/* a11y: autofocus */}
      <input autoFocus type="text" placeholder="Search events" />

      {/* a11y: positive tabIndex */}
      <div tabIndex={5}>
        Events tracked: {eventCount}
      </div>

      {/* Missing semicolon - format error */}
      <p>Last updated: {new Date().toLocaleString()}</p>
    </div>
  )
}
