// pages/users.js or app/users/page.js (depending on your routing setup)
'use client'; // if using App Router

import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabaseClient'; // adjust the path as necessary

export default function UsersPage() {
  const [users, setUsers] = useState([]);

  useEffect(() => {
    async function fetchUsers() {
      const { data, error } = await supabase.from('users').select('*');
      if (error) console.error('Error fetching users:', error.message);
      else setUsers(data);
    }

    fetchUsers();
  }, []);

  return (
    <div>
      <h1>Users data</h1>
      <ul>
        {users.map((user) => (
          <li key={user.id}>Email Address: {user.Email}</li> // adjust field names to match your table
        ))}
      </ul>
    </div>
  );
}
