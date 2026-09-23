import { useEffect, useState } from "react";
import "./index.css";

const API_URL = import.meta.env.VITE_API_URL || "http://localhost:8000";

function App() {
  const [tasks, setTasks] = useState([]);
  const [newTaskTitle, setNewTaskTitle] = useState("");
  const [error, setError] = useState("");

  useEffect(() => {
    loadTasks();
  }, []);

  async function loadTasks() {
    try {
      const response = await fetch(`${API_URL}/tasks`);
      const data = await response.json();
      setTasks(data);
    } catch {
      setError("Could not load tasks from the API.");
    }
  }

  async function addTask(event) {
    event.preventDefault();

    if (!newTaskTitle.trim()) {
      return;
    }

    try {
      const response = await fetch(`${API_URL}/tasks`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          title: newTaskTitle
        })
      });

      const newTask = await response.json();
      setTasks([...tasks, newTask]);
      setNewTaskTitle("");
    } catch {
      setError("Could not create the task.");
    }
  }

  async function toggleTask(task) {
    try {
      const response = await fetch(`${API_URL}/tasks/${task.id}`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          completed: !task.completed
        })
      });

      const updatedTask = await response.json();

      setTasks(
        tasks.map((currentTask) =>
          currentTask.id === updatedTask.id ? updatedTask : currentTask
        )
      );
    } catch {
      setError("Could not update the task.");
    }
  }

  return (
    <main className="app">
      <section className="card">
        <p className="eyebrow">AWS 3-Tier Project</p>
        <h1>Task Manager</h1>
        <p className="subtitle">
          React frontend connected to FastAPI and MySQL.
        </p>

        <form onSubmit={addTask}>
          <input
            type="text"
            value={newTaskTitle}
            onChange={(event) => setNewTaskTitle(event.target.value)}
            placeholder="Enter a new task"
          />
          <button type="submit">Add task</button>
        </form>

        {error && <p className="error">{error}</p>}

        <ul className="task-list">
          {tasks.map((task) => (
            <li key={task.id}>
              <label>
                <input
                  type="checkbox"
                  checked={task.completed}
                  onChange={() => toggleTask(task)}
                />
                <span className={task.completed ? "completed" : ""}>
                  {task.title}
                </span>
              </label>
            </li>
          ))}
        </ul>
      </section>
    </main>
  );
}

export default App;