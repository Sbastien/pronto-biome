import type { Todo } from "../types";

const STORAGE_KEY = "todos";

export function loadTodos(): Todo[] {
  const data = localStorage.getItem(STORAGE_KEY);
  if (!data) {
    return [];
  }
  return JSON.parse(data);
}

export function saveTodos(todos: Todo[]): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(todos));
}

export function generateId(): string {
  return crypto.randomUUID();
}
