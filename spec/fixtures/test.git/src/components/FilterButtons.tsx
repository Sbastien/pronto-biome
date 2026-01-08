import type { TodoFilter } from "../types";

interface FilterButtonsProps {
  current: TodoFilter;
  onChange: (filter: TodoFilter) => void;
  activeCount: number;
  hasCompleted: boolean;
  onClearCompleted: () => void;
}

const FILTERS: { value: TodoFilter; label: string }[] = [
  { value: "all", label: "All" },
  { value: "active", label: "Active" },
  { value: "completed", label: "Completed" },
];

export function FilterButtons({
  current,
  onChange,
  activeCount,
  hasCompleted,
  onClearCompleted,
}: FilterButtonsProps) {
  return (
    <div className="filters">
      <span className="count">{activeCount} items left</span>
      <div className="filter-buttons">
        {FILTERS.map(({ value, label }) => (
          <button
            key={value}
            type="button"
            className={current === value ? "active" : ""}
            onClick={() => onChange(value)}
          >
            {label}
          </button>
        ))}
      </div>
      {hasCompleted && (
        <button type="button" onClick={onClearCompleted}>
          Clear completed
        </button>
      )}
    </div>
  );
}
