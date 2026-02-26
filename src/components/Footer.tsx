export default function Footer() {
    return (
        <footer className="app-footer">
            <p className="app-footer-text">
                Created by{' '}
                <span className="app-footer-brand">Rikash</span>
                {' '}·{' '}
                <span>Easy-Score</span>
                {' '}·{' '}
                <span>© {new Date().getFullYear()}</span>
            </p>
        </footer>
    );
}
