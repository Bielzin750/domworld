// Optional PM2 configuration for a self-hosted DomWorld lobby service.
module.exports = {
	apps: [
		{
			name: "domworld-lobbies",
			script: "dist/src/main.js",
			cwd: __dirname,
			exec_mode: "fork",
			instances: 1,
			max_memory_restart: "1500M",
			kill_timeout: 3000,
			restart_delay: 2000,
			env: { RL_DIR: __dirname, NODE_ENV: "production" },
		},
	],
};
