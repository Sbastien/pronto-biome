import { FilterButtons } from "./components/FilterButtons";
import { TodoForm } from "./components/TodoForm";
import { TodoList } from "./components/TodoList";
import { useTodos } from "./hooks/useTodos";
import { countActive } from "./utils/filters";

export function App() {
  const {
    todos,
    allTodos,
    filter,
    setFilter,
    addTodo,
    toggleTodo,
    deleteTodo,
    clearCompleted,
  } = useTodos();

  const activeCount = countActive(allTodos);
  const hasCompleted = allTodos.some((todo) => todo.completed);

  return (
    <main className="todo-app">
      <h1>Todo App</h1>
      <TodoForm onAdd={addTodo} />
      <TodoList todos={todos} onToggle={toggleTodo} onDelete={deleteTodo} />
      <FilterButtons
        current={filter}
        onChange={setFilter}
        activeCount={activeCount}
        hasCompleted={hasCompleted}
        onClearCompleted={clearCompleted}
      />
    </main>
  );
}
