# Updating — Sync Workflow

Huong dan cap nhat khi context repo hoac source repo thay doi.

---

## Khi context repo update

### Symlink mode (khuyen nghi)

```bash
cd ~/robotnet10-claude-workspace
git pull
```

Tu dong nhan changes — khong can lam gi them vi `.claude/` trong RobotNet10 la symlink tro ve day.

### Copy mode

```bash
cd ~/robotnet10-claude-workspace
git pull

# Chay lai setup (se backup settings.local.json tu dong)
./setup.sh /path/to/robotnet10
```

## Khi source repo (robotnet10) thay doi

Context repo khong phu thuoc vao source repo structure. Chi can cap nhat neu:

1. **Source repo them projects moi** → cap nhat CLAUDE.md (project count, layer breakdown)
2. **Source repo doi folder structure** → cap nhat rules glob patterns
3. **Source repo them domain moi** → tao rule file moi trong `.claude/rules/`

## Source repo co nen commit `.claude/` rieng?

**Khuyen nghi: KHONG.** De context repo quan ly `.claude/`.

Neu source repo da co `.claude/`:
1. Xoa `.claude/` khoi source repo git tracking
2. Them `.claude/` vao source repo `.gitignore`
3. Chay setup script de tao symlink

```bash
# Tai source repo
cd /path/to/robotnet10
echo ".claude/" >> .gitignore
git rm -r --cached .claude/
git commit -m "Remove .claude/ from tracking, managed by context repo"

# Chay setup
cd ~/robotnet10-claude-workspace
./setup.sh /path/to/robotnet10
```

## Contribute nguoc lai context repo

Khi ban muon cap nhat rules, commands, hoac docs:

```bash
# Neu dung symlink: edit truc tiep tai .claude/ trong RobotNet10
# (symlink = edit tai cho, changes phan anh ve context repo)
cd ~/robotnet10-claude-workspace
git add .
git commit -m "update: description of changes"
git push

# Mo PR tren context repo neu lam viec theo team
```

## Giu settings.local.json rieng

`settings.local.json` la file user-specific (gitignored). Tao truc tiep trong `.claude/`:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm:*)"
    ]
  }
}
```

File nay KHONG bi ghi de khi chay setup script (da co backup logic).

## Conflict resolution

| Tinh huong | Giai phap |
|------------|-----------|
| Context repo va source repo deu co `.claude/CLAUDE.md` | Xoa `.claude/` khoi source repo, dung symlink |
| Hai developer co memory khac nhau | Memory user-specific da gitignored, khong conflict |
| Setup script mat settings.local.json | Script v1.0+ tu dong backup va restore |
| Rules trong context repo outdated so voi source | Cap nhat rules file, commit, team `git pull` |
