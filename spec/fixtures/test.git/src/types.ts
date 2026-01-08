export interface Todo {
  id: string;
  title: string;
  completed: boolean;
  createdAt: Date;
}

export type TodoFilter = "all" | "active" | "completed";

export interface TodoState {
  todos: Todo[];
  filter: TodoFilter;
}
