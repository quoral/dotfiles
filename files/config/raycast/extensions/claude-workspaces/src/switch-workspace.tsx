import { ActionPanel, Action, List, Icon, showToast, Toast } from "@raycast/api";
import { usePromise } from "@raycast/utils";
import { execSync } from "child_process";
import { readFileSync, existsSync } from "fs";
import { homedir } from "os";
import { basename, dirname } from "path";

const STATE_FILE = `${homedir()}/.local/state/cw/workspaces`;
const CODE_DIR = `${homedir()}/Code`;

function exec(cmd: string): string {
  try {
    return execSync(cmd, { encoding: "utf-8", timeout: 10000 }).trim();
  } catch {
    return "";
  }
}

interface Workspace {
  name: string;
  dir: string;
  windowCount: number;
}

interface Project {
  name: string;
  dir: string;
  org: string;
}

function getActiveWorkspaces(): Workspace[] {
  const allWs = exec("aerospace list-workspaces --all")
    .split("\n")
    .filter((ws) => ws.startsWith("p:") && !/[*\[\]\\]/.test(ws));

  const stateMap = new Map<string, string>();
  if (existsSync(STATE_FILE)) {
    for (const line of readFileSync(STATE_FILE, "utf-8").trim().split("\n")) {
      const [ws, dir] = line.split("\t");
      if (ws && dir) stateMap.set(ws, dir);
    }
  }

  return allWs.map((ws) => ({
    name: ws.replace(/^p:/, ""),
    dir: stateMap.get(ws) || "",
    windowCount: parseInt(exec(`aerospace list-windows --workspace "${ws}" --count`) || "0", 10),
  }));
}

function discoverProjects(): Project[] {
  const output = exec(
    `fd -H -t d '^\\.git$' "${CODE_DIR}" -d 4 --no-ignore --prune --exclude reviews --exclude sandbox --exclude node_modules --exec dirname {}`,
  );
  if (!output) return [];

  return output.split("\n").map((dir) => ({
    name: basename(dir),
    dir,
    org: basename(dirname(dir)),
  }));
}

function deriveWsName(projectDir: string, allProjects: Project[]): string {
  const base = basename(projectDir);
  const dupes = allProjects.filter((p) => p.name === base);
  if (dupes.length > 1) {
    return `p:${basename(dirname(projectDir))}/${base}`;
  }
  return `p:${base}`;
}

function switchToWorkspace(wsName: string) {
  exec(`aerospace workspace "${wsName}"`);
}

function openWorkspace(project: Project, allProjects: Project[]) {
  const wsName = deriveWsName(project.dir, allProjects);
  const winCount = parseInt(exec(`aerospace list-windows --workspace "${wsName}" --count`) || "0", 10);

  if (winCount > 0) {
    switchToWorkspace(wsName);
    showToast({ style: Toast.Style.Success, title: `Switched to ${wsName}` });
    return;
  }

  exec(`aerospace workspace "${wsName}"`);

  // Record in state file
  exec(`mkdir -p "$(dirname '${STATE_FILE}')"`);
  if (existsSync(STATE_FILE)) {
    exec(`grep -v "^${wsName}\t" "${STATE_FILE}" > "${STATE_FILE}.tmp" 2>/dev/null; mv "${STATE_FILE}.tmp" "${STATE_FILE}" 2>/dev/null; true`);
  }
  exec(`printf "%s\\t%s\\n" "${wsName}" "${project.dir}" >> "${STATE_FILE}"`);

  // Launch layout in background
  exec(`~/.local/bin/cw-layout "${wsName}" "${project.dir}" &`);
  showToast({ style: Toast.Style.Success, title: `Created ${wsName}` });
}

function closeWorkspace(ws: Workspace) {
  const wsName = `p:${ws.name}`;
  const windowIds = exec(`aerospace list-windows --workspace "${wsName}" --format '%{window-id}'`).split("\n");
  for (const wid of windowIds) {
    if (wid) exec(`aerospace close --window-id "${wid}"`);
  }
  if (existsSync(STATE_FILE)) {
    exec(`grep -v "^${wsName}\t" "${STATE_FILE}" > "${STATE_FILE}.tmp" 2>/dev/null; mv "${STATE_FILE}.tmp" "${STATE_FILE}" 2>/dev/null; true`);
  }
  exec("aerospace workspace-back-and-forth");
  showToast({ style: Toast.Style.Success, title: `Closed ${wsName}` });
}

export default function Command() {
  const { data, isLoading, revalidate } = usePromise(async () => {
    const active = getActiveWorkspaces();
    const projects = discoverProjects();
    return { active, projects };
  });

  const active = data?.active ?? [];
  const projects = data?.projects ?? [];

  return (
    <List isLoading={isLoading} searchBarPlaceholder="Search workspaces and projects...">
      {active.length > 0 && (
        <List.Section title="Active Workspaces">
          {active.map((ws) => (
            <List.Item
              key={ws.name}
              title={ws.name}
              subtitle={ws.dir.replace(homedir(), "~")}
              accessories={[{ text: `${ws.windowCount}w` }]}
              icon={Icon.Monitor}
              actions={
                <ActionPanel>
                  <Action
                    title="Switch to Workspace"
                    onAction={() => {
                      switchToWorkspace(`p:${ws.name}`);
                    }}
                  />
                  <Action
                    title="Close Workspace"
                    style={Action.Style.Destructive}
                    onAction={() => {
                      closeWorkspace(ws);
                      revalidate();
                    }}
                  />
                </ActionPanel>
              }
            />
          ))}
        </List.Section>
      )}
      <List.Section title="Open New Workspace">
        {projects
          .filter((p) => !active.some((ws) => ws.dir === p.dir))
          .map((p) => (
            <List.Item
              key={p.dir}
              title={p.name}
              subtitle={`${p.org}/${p.name}`}
              icon={Icon.Folder}
              actions={
                <ActionPanel>
                  <Action
                    title="Open Workspace"
                    onAction={() => {
                      openWorkspace(p, projects);
                    }}
                  />
                </ActionPanel>
              }
            />
          ))}
      </List.Section>
    </List>
  );
}
