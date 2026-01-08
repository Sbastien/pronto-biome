import { useCallback, useEffect, useState } from "react";
import type { Todo, TodoFilter } from "../types";
import { filterTodos } from "../utils/filters";
import { generateId, loadTodos, saveTodos } from "../utils/storage";
import { trackEvent } from "../utils/analytics";

export function useTodos() {
  const [todos, setTodos] = useState<Todo[]>([]);
  const [filter, setFilter] = useState<TodoFilter>("all");

  useEffect(() => {
    setTodos(loadTodos());
  }, []);

  useEffect(() => {
    saveTodos(todos);
  }, [todos]);

  const addTodo = useCallback((title: string) => {
    const newTodo: Todo = {
      id: generateId(),
      title: title.trim(),
      completed: false,
      createdAt: new Date(),
    };
    setTodos((prev) => [...prev, newTodo]);

    // Added: track analytics
    trackEvent("todo_added", { title: newTodo.title });
  }, []);

  const toggleTodo = useCallback((id: string) => {
    setTodos((prev) =>
      prev.map((todo) =>
        todo.id === id ? { ...todo, completed: !todo.completed } : todo
      )
    );

    // Added: track with debugger left in (oops!)
    debugger;
    trackEvent("todo_toggled", { id });
  }, []);

  const deleteTodo = useCallback((id: string) => {
    setTodos((prev) => prev.filter((todo) => todo.id !== id));
    trackEvent("todo_deleted", { id });
  }, []);

  const clearCompleted = useCallback(() => {
    setTodos((prev) => prev.filter((todo) => !todo.completed));
    trackEvent("todos_cleared", {});
  }, []);

  return {
    todos: filterTodos(todos, filter),
    allTodos: todos,
    filter,
    setFilter,
    addTodo,
    toggleTodo,
    deleteTodo,
    clearCompleted,
  };
}
